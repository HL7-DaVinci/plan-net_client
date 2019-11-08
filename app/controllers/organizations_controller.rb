# frozen_string_literal: true

################################################################################
#
# Organizations Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class OrganizationsController < ApplicationController
  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /organizations

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
      reply = @client.search(
        FHIR::Organization,
        search: {
          parameters: parameters.merge(
            _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
          )
        }
      )
    else
      reply = @client.search(
        FHIR::Organization,
        search: {
          parameters: {
            _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
          }
        }
      )
    end
      @bundle = reply.resource
    end

    update_bundle_links

    @query_params = query_params
    @organizations = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /organizations/[id]

  def show
    reply = @client.search(FHIR::Organization,
                           search: { parameters: { _id: params[:id] } })
    bundle = reply.resource
    fhir_organization = bundle.entry.map(&:resource).first

    @organization = Organization.new(fhir_organization) unless fhir_organization.nil?
  end

  def query_params
    [
      {
        name: 'Active',
        value: 'active'
      },
      {
        name: 'Address',
        value: 'address'
      },
      {
        name: 'City',
        value: 'address-city'
      },
      {
        name: 'Country',
        value: 'address-country'
      },
      {
        name: 'Coverage Area',
        value: 'coverage-area'
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
        name: 'Name',
        value: 'name'
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
        name: 'Qualification Code',
        value: 'qualification-code'
      },
      {
        name: 'Qualification Issuer',
        value: 'qualification-issuer'
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
      },
      {
        name: 'State',
        value: 'address-state'
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
      }
    ]
  end
end
