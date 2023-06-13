################################################################################
#
# Healthcare Services Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
require 'uri'

class HealthcareServicesController < ApplicationController

  before_action :connect_to_server

  #-----------------------------------------------------------------------------

  # GET /healthcare_services

  def index
    fetch_plans

    @params = {}
    @plans = @plans.collect{|p| [p[:name], p[:value]]}

    @networks     = @networks_by_plan.collect do |nyp| 
                      [
                        nyp.first, 
                        nyp.last.collect do |n| 
                          [n.display, n.reference]
                        end
                      ]
                    end

    @specialties  = SPECIALTIES.
                      sort_by { |code| code[:name] }.
                      collect{|n| [n[:name], n[:value]]}

    @categories   = HealthcareService.categories.
                      sort_by { |category| category[:name] }.
                      collect{|c| [c[:name], c[:value]]}
                      
    @types        = HealthcareService.types.
                      sort_by { |type| type[:name] }.
                      collect{|t| [t[:name], t[:value]]}

    @healthcare_services = [] 
  end

  #-----------------------------------------------------------------------------

  # GET /healthcare_services/[id]

  def show
  reply = @client.read(FHIR::HealthcareService, params[:id])
  fhir_healthcare_service = reply.resource
  @healthcare_service = HealthcareService.new(fhir_healthcare_service) unless fhir_healthcare_service.nil?
  end

  #-----------------------------------------------------------------------------

  # GET /healthcare_services/search

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _include: ['HealthcareService:organization', 'HealthcareService:location']
 #       _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-HealthcareService'
      }

      query_params = params[:healthcare_service]

      # Build the location-based query if zipcode and radius has been specified 
      modified_params = zip_plus_radius_to_address(query_params) if query_params 

      # Only include the allowed search parameters...
      filtered_params = HealthcareService.search_params.select { |key, _value| modified_params[key].present? }

      # Build the full query with the base parameters and the filtered parameters
      query = filtered_params.each_with_object(base_params) do |(local_key, fhir_key), search_params|
        search_params[fhir_key] = modified_params[local_key]
      end
      # Get the matching resources from the FHIR server
      @bundle = @client.search(
        FHIR::HealthcareService,
        search: { parameters: query }
      ).resource
    end

    @healthcare_services ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::HealthcareService }.map(&:resource)

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
