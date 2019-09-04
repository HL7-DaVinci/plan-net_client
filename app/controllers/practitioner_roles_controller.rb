################################################################################
#
# Practitioner Roles Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class PractitionerRolesController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /practitioner_roles

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::PractitionerRole, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::PractitionerRole)
			end
			@@bundle = reply.resource
		end

		@practitioner_roles = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /practitioner_roles/[id]

	def show
		reply = @@client.search(FHIR::PractitionerRole, 
											search: { parameters: { id: params[:id] } })
	end

end
