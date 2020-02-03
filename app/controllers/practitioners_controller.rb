# frozen_string_literal: true

################################################################################
#
# Practitioners Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class PractitionersController < ApplicationController
  before_action :connect_to_server, only: [:index, :show]

  # FHIR.logger.level = Logger::WARN
  #-----------------------------------------------------------------------------

  # GET /practitioners

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(
          FHIR::Practitioner,
          search: {
            parameters: parameters.merge(
              _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Practitioner'
            )
          }
        )
      else
        reply = @client.search(
          FHIR::Practitioner,
          search: {
            parameters: {
              _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Practitioner'
            }
          }
        )
      end
      @bundle = reply.resource
       @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end

    update_bundle_links

    @query_params = query_params
    @practitioners = @bundle.present? ? @bundle.entry.map(&:resource) : []
    @params = params
  end

  #-----------------------------------------------------------------------------

  # GET /practitioners/[id]

  def show
    reply = @client.search(FHIR::Practitioner,
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
        value: 'family:contains'
      },
      {
        name: 'Given name',
        value: 'given:contains'
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
        value: 'name:contains'
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
