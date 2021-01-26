# frozen_string_literal: true

################################################################################
#
# Locations Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class LocationsController < ApplicationController

  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /locations

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        query_params = query_hash_from_string(params[:query_string])
        modifiedparams = zip_plus_radius_to_address(query_params) if query_params 
        reply = @client.search(
          FHIR::Location,
          search: {
            parameters: modifiedparams.merge(
     #         _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
            )
          }
        )         
      else
        reply = @client.search(
          FHIR::Location,
          search: {
            parameters: {
      #        _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
            }
          }
        )
    end

      @bundle = reply.resource
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end

    update_bundle_links

    @query_params = Location.query_params
    @locations = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /locations/[id]

  def show
    reply = @client.read(FHIR::Location, params[:id])
    fhir_location = reply.resource
    @location = Location.new(fhir_location) unless fhir_location.nil?
  end

  #-----------------------------------------------------------------------------

  # This version is different than the one in the other two controllers, since it uses "address-postalcode" instead of "zip" and it uses "zip" and not :zip
  def zip_plus_radius_to_near(params)
    #  Convert zipcode + radius to  lat/long+radius in lat|long|radius|units format
    if params["address-postalcode"].present?   # delete zip and radius params and replace with near
      radius = 25
      zip = params["address-postalcode"]
      params.delete("address-postalcode")
      if params["radius"].present?
        radius = params["radius"]
        params.delete("radius")
      end
      # get coordinate
      coords = get_zip_coords(zip)
      near = "#{coords["lat"]}|#{coords["lng"]}|#{radius}|mi"
      params[:near]=near 
    end
    params
  end

end
