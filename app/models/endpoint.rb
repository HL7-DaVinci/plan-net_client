# frozen_string_literal: true

################################################################################
#
# Endpoint Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Endpoint < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :connection_type, :name, :managing_organization,
                :contacts, :period, :payload_types, :payload_mime_types,
                :headers

  #-----------------------------------------------------------------------------

  def initialize(endpoint)
    @id = endpoint.id
    @connection_type = endpoint.connectionType
    @name = endpoint.name
    @managing_organization = endpoint.managingOrganization
    @contacts = endpoint.contact
    @period = endpoint.period
    @payload_types = endpoint.payloadType
    @payload_mime_types = endpoint.payloadMimeType
    @headers = endpoint.header
  end

  #-----------------------------------------------------------------------------

  # FHIR search query parameters for Endpoints are:
  #
  #   _id, _language, connection-type, identifier, identifier-assigner, mime-type,
  #   name, organization, payload-type, status, usecase-standard, usecase-type,
  #   via-intermediary

  def self.search(server, query)
    parameters = {}

    query.each do |key, value|
      parameters[key] = value unless value.empty?
    end

    server.search(FHIR::Endpoint, search: { parameters: parameters })
  end

  #-----------------------------------------------------------------------------

  def self.query_params
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
