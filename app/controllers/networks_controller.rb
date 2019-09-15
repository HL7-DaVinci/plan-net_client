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
				reply = @@client.search(FHIR::Organization, 
											search: { parameters: { classification: params[:name],
											_profile: "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network" } })
			else
				reply = @@client.search(FHIR::Organization,
													search: { parameters: { 
														_profile: "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network"
													} })
			end
			@@bundle = reply.resource
		end

		@networks = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /insurance_plans/[id]

	def show
		reply = @@client.search(FHIR::Organization, 
											search: { parameters: { _id: params[:id], 
												_profile: "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network" } })
		bundle = reply.resource
		fhir_network = bundle.entry.map(&:resource).first
		
		@network = Network.new(fhir_network) unless fhir_network.nil?
	end

end
