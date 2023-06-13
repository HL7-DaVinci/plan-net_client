# frozen_string_literal: true

################################################################################
#
# Networks Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class NetworksController < ApplicationController
  
  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /networks

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(
          FHIR::Organization,
          search: {
            parameters: parameters.merge(
              type: 'ntwk'
          #    _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network'
            )
          }
        )
      else
        reply = @client.search(
          FHIR::Organization,
          search: {
            parameters: {
              type:   'ntwk'
          #    _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network'
            }
          }
        )
      end
      
      @bundle = reply.resource
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
     end

    update_bundle_links

    @query_params = Network.query_params
    @networks = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /network/[id]

  def show
    reply = @client.read(FHIR::Organization, params[:id])
    fhir_network = reply.resource
    #binding.pry 
    @network = Network.new(fhir_network) unless fhir_network.nil?
    @organization = @network 
  end

end
