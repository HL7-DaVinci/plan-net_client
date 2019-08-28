################################################################################
#
# Healthcare Services Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class HealthcareServicesController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /healthcare_services

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::HealthcareService, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::HealthcareService)
			end
			@@bundle = reply.resource
		end

		@healthcare_services = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /healthcare_services/[id]

	def show
		reply = @@client.search(FHIR::HealthcareService, 
											search: { parameters: { id: params[:id] } })
	end

end
