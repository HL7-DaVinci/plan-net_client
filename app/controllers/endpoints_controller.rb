# frozen_string_literal: true

################################################################################
#
# Endpoints Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class EndpointsController < ApplicationController
  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /endpoints

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(
          FHIR::Endpoint,
          search: {
            parameters: parameters.merge(
        #      _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Endpoint'
            )
          }
        )         
      else
        reply = @client.search(
          FHIR::Endpoint,
          search: {
            parameters: {
        #      _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Endpoint'
            }
          }
        )
      end

      @bundle = reply.resource
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end

    update_bundle_links

    @query_params = Endpoint.query_params
    @endpoints = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /endpoints/[id]

  def show
    reply = @client.read(FHIR::Endpoint, params[:id])
    fhir_endpoint = reply.resource
    @endpoint = Endpoint.new(fhir_endpoint) unless fhir_endpoint.nil?
  end

end
