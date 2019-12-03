# frozen_string_literal: true

################################################################################
#
# Practitioner Roles Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class PractitionerRolesController < ApplicationController
  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /practitioner_roles

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(
          FHIR::PractitionerRole,
          search: {
            parameters: parameters.merge(
              _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-PractitionerRole'
            )
          }
        )
      else
        reply = @client.search(
          FHIR::PractitionerRole,
          search: {
            parameters: {
              _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-PractitionerRole'
            }
          }
        )
      end

      @bundle = reply.resource
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url)
    end

    update_bundle_links

    @query_params = query_params
    @practitioner_roles = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /practitioner_roles/[id]

  def show
    reply = @client.search(FHIR::PractitionerRole,
                           search: { parameters: { id: params[:id] } })
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
        value: 'available-endtime'
      },
      {
        name: 'Available Start Time',
        value: 'available-start-time'
      },
      {
        name: 'Date',
        value: 'date'
      },
      {
        name: 'Email',
        value: 'email'
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
        value: 'intermediary'
      },
      {
        name: 'Location',
        value: 'location'
      },
      {
        name: 'Network',
        value: 'network'
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
        name: 'Phone',
        value: 'phone'
      },
      {
        name: 'Practitioner',
        value: 'practitioner'
      },
      {
        name: 'Telecom',
        value: 'telecom'
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
        name: 'Role',
        value: 'role'
      },
      {
        name: 'Service',
        value: 'service'
      },
      {
        name: 'Specialty',
        value: 'specialty'
      }
    ]
  end
end
