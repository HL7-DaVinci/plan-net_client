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
require 'pry'

class PharmaciesController < ApplicationController

  before_action :connect_to_server

  #-----------------------------------------------------------------------------

  # GET /pharmacies

  def index
    fetch_plans

    @params = {}
    @specialties = PHARMACY_SPECIALTIES.
            sort_by { |code| code[:name] }.
            collect{|n| [n[:name], n[:value]]}

    @plans = @plans.collect{|p| [p[:name], p[:value]]}

    @networks = @networks_by_plan.collect do |nyp| 
                  [
                    nyp.first, 
                    nyp.last.collect do |n| 
                      [n.display, n.reference]
                    end
                  ]
                end
  end

  #-----------------------------------------------------------------------------

  # GET /pharmacies/search

  # Need to update the query plan.   Current query retrieves all Locations that have an organization affiliation with ONE of (the right network,
  # the right role).   The key relationship is pharmacy locations that are assocaited with a network.  Filtering the organizational affiliations
  # on the client side, and eliminating the locations that are only referenced by OAs with the wrong type

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _revinclude: ['OrganizationAffiliation:location']
   #     type: 'OUTPHARM',
   # _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
      }

      query_params = params[:pharmacy]

      # Build the location-based query if zipcode and radius has been specified 
      if query_params
        modified_params = zip_plus_radius_to_address(query_params) 
      else
        modified_params={}
      end
      modified_params[:role]="pharmacy" 
      # Only include the allowed search parameters...
      filtered_params = Location.search_params.select { |key, _value| modified_params[key].present? }
      # Build the full query with the base parameters and the filtered parameters
      query = filtered_params.each_with_object(base_params) do |(local_key, fhir_key), search_params|
        search_params[fhir_key] = modified_params[local_key]
      end
      # Get the matching resources from the FHIR server
      @bundle = @client.search(
        FHIR::Location,
        search: { parameters: query }
      ).resource
    end

    fhir_locations ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::Location }.map(&:resource)
    fhir_orgaffs ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::OrganizationAffiliation }.map(&:resource)
    @locations = {}
    @orgaffs = []
    binding.pry 
    fhir_locations.map  do  |fhir_location| 
      @locations["Location/" + fhir_location.id] =  Location.new(fhir_location)  # build a hash, and then convert to array
    end
    fhir_orgaffs.map  do  |fhir_orgaff| 
      @orgaffs << OrganizationAffiliation.new(fhir_orgaff)
    end
    binding.pry 
    # Now, iterate through the orgaffs, and mark the locations associated with orgaffs that satisfy the filter criteria
    #  if query_params["network"] filter by contains_code(orgaff.network, query_Params["network"])
    #  if query_params["specialty"] filter by contains_code(orgaff.specialty, query_Params["network"])
    #  if always filter by contains_code(orgaff.codes, "pharmacy")
    #  if an orgaff passes, then mark its locations with checked=true
    @orgaffs.map do |orgaff|
      checked = true
      binding.pry 
      checked &= reference_contained(orgaff.networks, query_params["network"] ) if  query_params["network"].size > 0
      checked &= code_contained(orgaff.specialties, query_params["specialty"] ) if  query_params["specialty"].size > 0
      checked &= code_contained(orgaff.codes, "pharmacy" )  

      if(checked)
        orgaff.locations.map do |location|
          @locations[location.reference].checked = true if @locations[location.reference]
        end
      end
    end

    @locations = @locations.values.select{ |loc| loc.checked}    # -- need to sort this out  SAK
    # @locations = @locations.values 

    # Prepare the query string for display on the page
    @search = "<Search String in Returned Bundle is empty>"
    @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 

    # Prepare the links for the Next and Previous buttons
    update_bundle_links

    respond_to do |format|
      format.js {}
    end
  end

    # Return true if coding includes code
  def code_contained(list, code)
    result = false
    list.map(&:coding).each do |coding|
        result |= coding.map(&:code).first == code 
    end
    result 
  end

  # Return true if array includes reference ref
  def reference_contained(list, ref)
    result = false

    list.map do |r|
        result |= r.reference == ref 
    end
    result 
  end

 
end
