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

  #-----------------------------------------------------------------------------

  # GET /pharmacies

  def index
    fetch_plans

    @params = {}

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

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _revinclude: ['OrganizationAffiliation:location'], type: 'OUTPHARM',
        _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
      }

      query_params = params[:pharmacy]

      # Build the location-based query if zipcode and radius has been specified 
      modified_params = zip_plus_radius_to_address(query_params) if query_params 

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

    @locations ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::Location }.map(&:resource)

    # Prepare the query string for display on the page
    @search = "<Search String in Returned Bundle is empty>"
    @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 

    # Prepare the links for the Next and Previous buttons
    update_bundle_links

    respond_to do |format|
      format.js {}
    end
  end

end
