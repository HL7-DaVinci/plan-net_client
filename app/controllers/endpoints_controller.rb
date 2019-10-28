################################################################################
#
# Endpoints Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class EndpointsController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /endpoints

	def index
		if params[:page].present?
			update_page(params[:page])
		else
			if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
				reply = @client.search(FHIR::Endpoint,
                                search: { parameters: parameters })
			else
				reply = @client.search(FHIR::Endpoint)
			end
			@bundle = reply.resource
		end

    update_bundle_links

    @query_params = query_params
		@endpoints = @bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /endpoints/[id]

	def show
		reply = @client.search(FHIR::Endpoint,
											search: { parameters: { _id: params[:id] } })
		bundle = reply.resource
		fhir_endpoint = bundle.entry.map(&:resource).first

		@endpoint = Endpoint.new(fhir_endpoint) unless fhir_endpoint.nil?
	end

  def query_params
    [
      {
        name: 'Connection Type',
        value: 'connection-type'
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
        name: 'MIME Type',
        value: 'mime-type'
      },
      {
        name: 'Name',
        value: 'name'
      },
      {
        name: 'Organization',
        value: 'organization'
      },
      {
        name: 'Payload Type',
        value: 'payload-type'
      },
      {
        name: 'Status',
        value: 'status'
      },
      {
        name: 'Use Case Standard',
        value: 'usecase-standard'
      },
      {
        name: 'Use Case Type',
        value: 'usecase-type'
      }
    ]
  end
end
