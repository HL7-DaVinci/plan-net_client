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
			if params[:query].present?
				@query = params[:query]
				reply = Endpoint.search(@@client, @query)
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
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_endpoint = bundle.entry.map(&:resource).first
		
		@endpoint = Endpoint.new(fhir_endpoint) unless fhir_endpoint.nil?
	end

end
