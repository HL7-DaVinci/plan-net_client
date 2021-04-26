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
require 'dalli'

class PharmaciesController < ApplicationController

  before_action :connect_to_server
  before_action :setup_dalli

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

  # Need to update the query plan.  Current query retrieves all Locations that 
  # have an organization affiliation with ONE of (the right network, the right role).   
  #
  # The key relationship is pharmacy locations that are associated with a network.  
  # Filtering the organization affiliations on the client side, and eliminating 
  # the locations that are only referenced by organization affiliations with the 
  # wrong type.

  def search
  
    if params[:page].present?
      # Temporary
      if Rails.env.production?
        @locations = Rails.cache.read("pharmacy-locations-#{session.id}")
      else
        @locations = @dalli_client.get("pharmacy-locations-#{session.id}")
      end

      case params[:page]
      when 'previous'
        session[:offset] -= 20
      when 'next'
        session[:offset] += 20 
      end
      session[:offset] = [session[:offset],0].max 
      session[:offset] = [session[:offset],@locations.count-1].min 
    else
      base_params = {
        _revinclude: ['OrganizationAffiliation:location']
        # type: 'OUTPHARM',
        # _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
      }

      query_params = params[:pharmacy]

      # Build the location-based query if zipcode and radius has been specified 
      if query_params
        modified_params = zip_plus_radius_to_address(query_params) 
      else
        modified_params = {}
      end

      modified_params[:role] = "pharmacy" 
      # if network and specialty are present, filter those on the client.
      network = modified_params["network"].length > 0 ? modified_params["network"] :  nil 
      specialty = modified_params["specialty"].length > 0 ? modified_params["specialty"] :  nil 
      modified_params.delete("network")
      modified_params.delete("specialty")
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

      session[:search] = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first

      @locations = {}
      @orgaffs = []

      # Build the Ruby models to represent all of the FHIR data
      loop do
        fhir_locations = filter(@bundle.entry.map(&:resource), "Location")
        fhir_orgaffs = filter(@bundle.entry.map(&:resource), "OrganizationAffiliation")

        fhir_locations.map do |fhir_location| 
          # build a hash, and then convert to array
          @locations["Location/" + fhir_location.id] = Location.new(fhir_location)  
        end

        fhir_orgaffs.map do |fhir_orgaff| 
          @orgaffs << OrganizationAffiliation.new(fhir_orgaff)
        end

        break unless @bundle.next_link.present?
        url = @bundle.next_link.url
        break unless url.present?
        @bundle = @client.parse_reply(FHIR::Bundle, @client.default_format, @client.raw_read_url(url))
      end
  
      # now we have all of the content, we can now process the content
      # Now, iterate through the orgaffs, and mark the locations associated with orgaffs that satisfy the filter criteria
      #  if query_params["network"] filter by contains_code(orgaff.network, query_Params["network"])
      #  if query_params["specialty"] filter by contains_code(orgaff.specialty, query_Params["specialty"])
      #  if always filter by contains_code(orgaff.codes, "pharmacy")
      #  if an orgaff passes, then mark its locations with checked=true

      @orgaffs.map do |orgaff|
        checked = true
        checked &= reference_contained(orgaff.networks, network  ) if network
        checked &= code_contained(orgaff.specialties, specialty ) if specialty 
        checked &= code_contained(orgaff.codes, "pharmacy" )  
        if (checked)
          orgaff.locations.map do |location|
            @locations[location.reference].checked = true if @locations[location.reference]
          end
        end
      end
      @locations = @locations.values.select{ |loc| loc.checked }
      # Temporary
      if Rails.env.production?
        Rails.cache.write("pharmacy-locations-#{session.id}", @locations)
      else
        @dalli_client.set("pharmacy-locations-#{session.id}", @locations) 
      end

      session[:offset] = 0 

      #binding.pry 

      # Prepare the query string for display on the page
      #@search = "<Search String in Returned Bundle is empty>"
      #@search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 

      # Prepare the links for the Next and Previous buttons
      # update_bundle_links   # need to sort this out
    end

    @items = @locations.slice(session[:offset], PAGE_SIZE)
    @search = session[:search] 

    respond_to do |format|
      format.js { }
    end
  end

  #-----------------------------------------------------------------------------

  # Filter out resources that don't match the requested type

  def filter(fhir_resources, type)
    fhir_resources.select do |resource| 
      resource.resourceType == type
    end
  end

  #-----------------------------------------------------------------------------

  # Return true if coding includes code

  def code_contained(list, code)
    result = false

    list.map(&:coding).each do |coding|
      result |= coding.map(&:code).first == code 
    end

    result 
  end

  #-----------------------------------------------------------------------------

  # Return true if array includes reference ref

  def reference_contained(list, ref)
    result = false

    list.map do |r|
      result |= r.reference == ref 
    end

    result 
  end

end
