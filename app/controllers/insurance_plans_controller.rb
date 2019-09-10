################################################################################
#
# Insurance Plans Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class InsurancePlansController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /insurance_plans

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:name].present?
				reply = @@client.search(FHIR::InsurancePlan, 
											search: { parameters: { classification: params[:name] } })
			else
				reply = @@client.search(FHIR::InsurancePlan)
			end
			@@bundle = reply.resource
		end

		@insurance_plans = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /insurance_plans/[id]

	def show
		reply = @@client.search(FHIR::InsurancePlan, 
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_insurnace_plan = bundle.entry.map(&:resource).first
		
		@insurance_plan = InsurancePlan.new(fhir_insurnace_plan) unless fhir_insurnace_plan.nil?
	end

end