################################################################################
#
# Practitioners Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class PractitionersController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /practitioners

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::Practitioner, 
											search: { parameters: { family: params[:name], _sort: :given } })
			else
				reply = @@client.search(FHIR::Practitioner,
											search: { parameters: { _sort: :family } } )
			end
			@@bundle = reply.resource
		end

		@practitioners = @@bundle.present? ? @@bundle.entry.map(&:resource) : []
		@params = params
	end

	#-----------------------------------------------------------------------------

	# GET /practitioners/[id]

	def show
		reply = @@client.search(FHIR::Practitioner, 
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_practitioner = bundle.entry.map(&:resource).first
		
		@practitioner = Practitioner.new(fhir_practitioner) unless fhir_practitioner.nil?
	end

end
