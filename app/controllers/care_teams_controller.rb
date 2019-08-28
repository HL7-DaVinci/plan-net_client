################################################################################
#
# Care Teams Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class CareTeamsController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /care_teams

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::CareTeam, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::CareTeam)
			end
			@@bundle = reply.resource
		end

		@care_teams = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /care_teams/[id]

	def show
		reply = @@client.search(FHIR::CareTeam, 
											search: { parameters: { id: params[:id] } })
	end

end
