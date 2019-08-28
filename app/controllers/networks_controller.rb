################################################################################
#
# Networks Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class NetworksController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /networks

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::Network, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::Organization,
													search: { parameters: { 
														profile: "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network" 
													} })
			end
			@@bundle = reply.resource
		end

		@networks = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /insurance_plans/[id]

	def show
		reply = @@client.search(FHIR::Network, 
											search: { parameters: { id: params[:id] } })
	end

end
