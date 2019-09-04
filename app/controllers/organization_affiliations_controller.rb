################################################################################
#
# Organization Affiliations Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class OrganizationAffiliationsController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /organization_affiliations

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::OrganizationAffiliation, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::OrganizationAffiliation)
			end
			@@bundle = reply.resource
		end

		@organization_affiliations = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /organization_affiliations/[id]

	def show
		reply = @@client.search(FHIR::OrganizationAffiliation, 
											search: { parameters: { id: params[:id] } })
	end

end
