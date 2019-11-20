# frozen_string_literal: true

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

  # GET /pharmacies/networks

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

  # GET /pharmacies/search

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _revinclude: ['OrganizationAffiliation:location'],
        type: 'OUTPHARM',
        _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
      }
      initparams = params 
      modifiedparams = zip_plus_radius_to_near(initparams) if initparams 
       query =
        SEARCH_PARAMS
          .select { |key, _value| modifiedparams[key].present? }
          .each_with_object(base_params) do |(local_key, fhir_key), search_params|
            search_params[fhir_key] = modifiedparams[local_key]
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

  private

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
    telecom.system + ': ' + telecom.value
  end


  def format_zip(zip)
    if zip.length > 5
      "#{zip[0..4]}-#{zip[5..-1]}"
    else
      zip
    end
  end

  
  SEARCH_PARAMS = {
    network: '_has:OrganizationAffiliation:location:network',
    near: 'near',
    city: 'address-city',
    name: 'name:contains'
  }.freeze


  def zip_plus_radius_to_near(params)
    #  Convert zipcode + radius to  lat/long+radius in lat|long|radius|units format
    if params[:zip].present?   # delete zip and radius params and replace with near
      radius = 25
      zip = params[:zip]
      params.delete(:zip)
      if params[:radius].present?
        radius = params[:radius]
        params.delete(:radius)
      end
      # get coordinate
      coords = get_zip_coords(zip)
      near = "#{coords["lat"]}|#{coords["lng"]}|#{radius}|mi"
      params[:near]=near 
    end
    params
  end

    # Geolocation from MapQuest... 
    # <<< probably should put Key in CONSTANT and put it somewhere more rational than inline >>>>
def get_zip_coords(zipcode)
  response = HTTParty.get(
    'http://open.mapquestapi.com/geocoding/v1/address',
    query: {
      key: 'A4F1XOyCcaGmSpgy2bLfQVD5MdJezF0S',
      postalCode: zipcode,
      country: 'USA',
      thumbMaps: false
    }
  )

  # coords = response.deep_symbolize_keys&.dig(:results)&.first&.dig(:locations).first&.dig(:latLng)
  coords = response["results"].first["locations"].first["latLng"]

end

end
