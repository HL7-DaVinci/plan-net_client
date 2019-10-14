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
			update_page(params[:page])
		else
			if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
				reply = @client.search(FHIR::HealthcareService,
											search: { parameters: parameters })
			else
				reply = @client.search(FHIR::HealthcareService)
			end
			@bundle = reply.resource
		end

    update_bundle_links

    @query_params = query_params
		@healthcare_services = @bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /healthcare_services/[id]

	def show
		reply = @client.search(FHIR::Organization, 
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_healthcare_service = bundle.entry.map(&:resource).first

		@healthcare_service = HealthcareService.new(fhir_healthcare_service) unless 
															fhir_healthcare_service.nil?
	end

  def query_params
    [
      {
        name: 'Active',
        value: 'active'
      },
      {
        name: 'Available Days',
        value: 'available-days'
      },
      {
        name: 'Available End Time',
        value: 'available-end-time'
      },
      {
        name: 'Available Start Time',
        value: 'available-start-time'
      },
      {
        name: 'Characteristic',
        value: 'characteristic'
      },
      {
        name: 'Coverage Area',
        value: 'coverage-area'
      },
      {
        name: 'Eligibility',
        value: 'eligibility'
      },
      {
        name: 'Endpoint',
        value: 'endpoint'
      },
      {
        name: 'ID',
        value: '_id'
      },
      {
        name: 'Identifier',
        value: 'identifier'
      },
      {
        name: 'Identifier Assigner',
        value: 'identifier-assigner'
      },
      {
        name: 'Intermediary',
        value: 'via-intermediary'
      },
      {
        name: 'Location',
        value: 'location'
      },
      {
        name: 'Name',
        value: 'name'
      },
      {
        name: 'New Patient',
        value: 'new-patient'
      },
      {
        name: 'New Patient Network',
        value: 'new-patient-network'
      },
      {
        name: 'Organization',
        value: 'organization'
      },
      {
        name: 'Program',
        value: 'program'
      },
      {
        name: 'Service Category',
        value: 'service-category'
      },
      {
        name: 'Service Type',
        value: 'service-type'
      },
      {
        name: 'Specialty',
        value: 'specialty'
      }
    ]
  end
end
