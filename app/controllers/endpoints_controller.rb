################################################################################
#
# Endpoints Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class EndpointsController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /endpoints

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::Endpoint, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::Endpoint)
			end
			@@bundle = reply.resource
		end

		@endpoints = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /endpoints/[id]

	def show
		reply = @@client.search(FHIR::Endpoint, 
											search: { parameters: { id: params[:id] } })
	end

end
