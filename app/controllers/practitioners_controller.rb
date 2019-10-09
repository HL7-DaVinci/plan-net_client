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

  # FHIR.logger.level = Logger::WARN
	#-----------------------------------------------------------------------------

	# GET /practitioners

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string]).merge(_sort: :family)
				reply = @@client.search(FHIR::Practitioner,
											search: { parameters: parameters })
			else
				reply = @@client.search(FHIR::Practitioner,
											search: { parameters: { _sort: :family } } )
			end
			@@bundle = reply.resource
		end

    @query_params = query_params
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

  def query_params
    [
      {
        name: 'Endpoint',
        value: 'endpoint'
      },
      {
        name: 'Family name',
        value: 'family'
      },
      {
        name: 'Given name',
        value: 'given'
      },
      {
        name: 'Identfier Assigner',
        value: 'identifier-assigner'
      },
      {
        name: 'Identifier',
        value: 'identifier'
      },
      {
        name: 'Name',
        value: 'name'
      },
      {
        name: 'Phonetic',
        value: 'phonetic'
      },
      {
        name: 'Qualification Code',
        value: 'qualification-code'
      },
      {
        name: 'Qualification Issuer',
        value: 'qualification-issuer'
      },
      {
        name: 'Qualification Period',
        value: 'qualification-period'
      },
      {
        name: 'Qualification Status',
        value: 'qualification-status'
      },
      {
        name: 'Qualification Where Valid Code',
        value: 'qualification-wherevalid-code'
      },
      {
        name: 'Qualification Where Valid Location',
        value: 'qualification-wherevalid-location'
      }
    ]
  end
end
