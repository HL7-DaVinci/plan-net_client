################################################################################
#
# Providers Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class ProvidersController < ApplicationController

	before_action :connect_to_server
  before_action :fetch_payers, only: [:index]

	#-----------------------------------------------------------------------------

	# GET /providers

	def index
    @params = {}
	end

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
end
