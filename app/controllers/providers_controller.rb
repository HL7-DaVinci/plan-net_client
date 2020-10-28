# frozen_string_literal: true

################################################################################
#
# Providers Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
require 'uri'

class ProvidersController < ApplicationController

  before_action :connect_to_server

  #-----------------------------------------------------------------------------

  # GET /providers

  def index
    fetch_plans

    @params = {}
    @specialties = INDIVIDUAL_AND_GROUP_SPECIALTIES.
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

  # GET /providers/networks

  def networks
    id = params[:_id]
    fetch_plans(id)
    networks = @networks_by_plan[id]
    network_list = networks.map do |entry|
      {
        value: entry.reference,
        name: entry.display
      }
    end
    render json: network_list
  end

  #-----------------------------------------------------------------------------

  # GET /providers/search

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _include: ['PractitionerRole:practitioner', 'PractitionerRole:location'],
  #      _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-PractitionerRole'
      }

      query_params = params[:provider]

      # Build the location-based query if zipcode and radius has been specified 
      if query_params
        modified_params = zip_plus_radius_to_address(query_params) 
      else
        modified_params={}
      end
      modified_params[:role] = "provider" 

      # Only include the allowed search parameters...
      filtered_params = Practitioner.search_params.select { |key, _value| modified_params[key].present? }

      # Build the full query with the base parameters and the filtered parameters
      query = filtered_params.each_with_object(base_params) do |(local_key, fhir_key), search_params|
        search_params[fhir_key] = modified_params[local_key]
      end

      @bundle = @client.search(
        FHIR::PractitionerRole,
        search: { parameters: query }
      ).resource
    end

    @practitioners ||= @bundle.entry.
                        select { |entry| entry.resource.instance_of? FHIR::Practitioner }.
                        map(&:resource)
  
    # Prepare the query string for display on the page
    @search = "<Search String in Returned Bundle is empty>"
    @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 


    # Prepare the links for the Next and Previous buttons
    update_bundle_links

    respond_to do |format|
      format.js {}
    end
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

  def providers
    practitioners.map do |practitioner|
      roles = practitioner_roles(practitioner.id)
      photo = Practitioner.new(practitioner).photo
      practitioner_locations = role_locations(roles.flat_map(&:location).map(&:reference))
      {
        id: practitioner.id,
        name: display_human_name(practitioner.name.first),
        gender: practitioner.gender,
        specialty: practitioner.qualification.map(&:code).map(&:text).compact.uniq,
        telecom: roles.flat_map(&:telecom).map { |telecom| display_telecom(telecom) },
        address: practitioner_locations.flat_map(&:address).map { |address| display_address(address) },
        photo: photo
      }
    end
  end

  #-----------------------------------------------------------------------------

  def practitioner_roles(practitioner_id)
    roles.select { |role| role.practitioner.reference.end_with? practitioner_id }
  end

  #-----------------------------------------------------------------------------

  def role_locations(location_references)
    location_references.map { |reference| locations.find { |location| reference.end_with? location.id } }
  end

  #-----------------------------------------------------------------------------

  def locations
    @locations ||= @bundle.entry.
                      select { |entry| entry.resource.instance_of? FHIR::Location }.
                      map(&:resource)
  end

  #-----------------------------------------------------------------------------

  def roles
    @roles ||= @bundle.entry.
                      select { |entry| entry.resource.instance_of? FHIR::PractitionerRole }.
                      map(&:resource)
  end

end
