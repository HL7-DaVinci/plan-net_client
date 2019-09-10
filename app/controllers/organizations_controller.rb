################################################################################
#
# Organizations Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class OrganizationsController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /organizations

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::Organization, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::Organization)
			end
			@@bundle = reply.resource
		end

		@organizations = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /organizations/[id]

	def show
		reply = @@client.search(FHIR::Organization, 
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_organization = bundle.entry.map(&:resource).first
		
		@organization = Organization.new(fhir_organization) unless fhir_organization.nil?
	end

end
