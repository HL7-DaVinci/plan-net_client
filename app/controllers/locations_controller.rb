################################################################################
#
# Locations Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class LocationsController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /locations

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::Location, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::Location)
			end
			@@bundle = reply.resource
		end

		@locations = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /locations/[id]

	def show
		reply = @@client.search(FHIR::Location, 
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_location = bundle.entry.map(&:resource).first
		
		@location = Location.new(fhir_location) unless fhir_location.nil?
	end

end
