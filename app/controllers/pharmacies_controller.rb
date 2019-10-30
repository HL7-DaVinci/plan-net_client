################################################################################
#
# Pharmacies Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class PharmaciesController < ApplicationController
	before_action :connect_to_server
  before_action :fetch_payers, only: [:index]

	#-----------------------------------------------------------------------------

	# GET /pharmacies

	def index
    @params = {}
	end

  def networks
    id = params[:payer_id]
    network_list = @client.search(
      FHIR::Organization,
      search: { parameters: {
                  _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network',
                  partof: "Organization/#{id}"
                } }
    )&.resource&.entry&.map do |entry|
      {
        value: entry&.resource&.id,
        name: entry&.resource&.name
      }
    end

    render json: network_list
  end

  def search
    if params[:page].present?
			update_page(params[:page])
    else
      base_params = {
        _revinclude: ['OrganizationAffiliation:location'],
        type: 'OUTPHARM'
      }
      query =
        SEARCH_PARAMS
          .select { |key, _value| params[key].present? }
          .each_with_object(base_params) do |(local_key, fhir_key), search_params|
            search_params[fhir_key] = params[local_key]
          end

      @bundle = @client.search(
        FHIR::Location,
        search: { parameters: query }
      ).resource
    end

    update_bundle_links

    render json: {
             pharmacies: pharmacies,
             nextPage: @next_page_disabled,
             previousPage: @previous_page_disabled
           }
  end

  def pharmacies
    locations
      .map do |location|
        {
          id: location.id,
          name: location.name,
          telecom: location.telecom.map { |telecom| display_telecom(telecom) },
          address: display_address(location.address)
        }
      end
  end

  def org_affiliations
    @org_affiliations ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::OrganizationAffiliation }.map(&:resource)
  end

  def org_for_location(location_id)
    org_affiliations.find { |org_aff| org_aff.locations.any? { |location| location.reference.end_with? location_id } }
  end

  def locations
    @locations ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::Location }.map(&:resource)
  end

	def display_telecom(telecom)
		return telecom.system + ": " + telecom.value
	end

  def display_address(address)
    return address.line.join('<br>') + "<br>#{address.city}, #{address.state} #{address.postalCode}"
  end

  def format_zip(zip)
    if (zip.length > 5)
      "#{zip[0..4]}-#{zip[5..-1]}"
    else
      zip
    end
  end

  SEARCH_PARAMS = {
    network: '_has:OrganizationAffiliation:location:network',
    zip: 'address-postalcode',
    city: 'address-city',
    name: 'name:contains'
  }
end
