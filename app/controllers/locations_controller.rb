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
			if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
				reply = @@client.search(FHIR::Location,
											search: { parameters: parameters })
			else
				reply = @@client.search(FHIR::Location)
			end
			@@bundle = reply.resource
		end

    @query_params = query_params
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

  def query_params
    [
      {
        name: 'ID',
        value: '_id'
      },
      {
        name: 'Accessibility',
        value: 'accessibility'
      },
      {
        name: 'Address',
        value: 'address'
      },
      {
        name: 'Available Days',
        value: 'available-days'
      },
      {
        name: 'Available End Time',
        value: 'available-endtime'
      },
      {
        name: 'Available Start Time',
        value: 'available-start-time'
      },
      {
        name: 'City',
        value: 'address-city'
      },
      {
        name: 'Contains',
        value: 'contains'
      },
      {
        name: 'Country',
        value: 'address-country'
      },
      {
        name: 'endpoint',
        value: 'Endpoint'
      },
      {
        name: 'Identifier',
        value: 'identifier'
      },
      {
        name: 'Intermediary',
        value: 'via-intermediary'
      },
      {
        name: 'Identifier Assigner',
        value: 'identifier-assigner'
      },
      {
        name: 'New Patient Network',
        value: 'new-patient-network'
      },
      {
        name: 'Near',
        value: 'near'
      },
      {
        name: 'New Patient',
        value: 'new-patient'
      },
      {
        name: 'Operational Status',
        value: 'operational-status'
      },
      {
        name: 'Organization',
        value: 'organization'
      },
      {
        name: 'Part of',
        value: 'partof'
      },
      {
        name: 'Postal Code',
        value: 'address-postalcode'
      },
      {
        name: 'State',
        value: 'address-state'
      },
      {
        name: 'Status',
        value: 'status'
      },
      {
        name: 'Telecom Available Days',
        value: 'telecom-available-days'
      },
      {
        name: 'Telecom Available End Time',
        value: 'telecom-available-endtime'
      },
      {
        name: 'Telecom Available Start Time',
        value: 'telecom-available-start-time'
      },
      {
        name: 'Type',
        value: 'type'
      },
      {
        name: 'Use',
        value: 'address-use'
      }
    ]
  end
end
