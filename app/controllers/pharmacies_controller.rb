# frozen_string_literal: true

################################################################################
#
# Pharmacies Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
require 'uri'

class PharmaciesController < ApplicationController
  before_action :connect_to_server
  before_action :fetch_plans, only: [:index]

  #-----------------------------------------------------------------------------

  # GET /pharmacies

  def index
    @params = {}
  end

  

  # GET /pharmacies/search

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _revinclude: ['OrganizationAffiliation:location'],
        _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
      }
      query_params = params 
      modifiedparams = zip_plus_radius_to_address(query_params) if query_params 
      modifiedparams[:role]="pharmacy" 
      query = SEARCH_PARAMS
                .select { |key, _value| modifiedparams[key].present? }
                .each_with_object(base_params) do |(local_key, fhir_key), search_params|
                  search_params[fhir_key] = modifiedparams[local_key]
                end
      
       @bundle = @client.search(
         FHIR::Location,
         search: { parameters: query }).resource 
         # binding.pry 
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
 
    end
    update_bundle_links
    render json: {
      pharmacies: pharmacies,
      nextPage: @next_page_disabled,
      previousPage: @previous_page_disabled,
  #    searchParams: preparequerytext(query,"Location")
      searchParams: @search 
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
    role:     '_has:OrganizationAffiliation:location:role',
    network: '_has:OrganizationAffiliation:location:network',
    address: 'address',
    city: 'address-city',
    name: 'name:contains'
  }.freeze


 
end
