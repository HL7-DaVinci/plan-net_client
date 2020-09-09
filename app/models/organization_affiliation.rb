# frozen_string_literal: true

################################################################################
#
# OrganizationAffiliation Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class OrganizationAffiliation < Resource

  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :networks, :identifiers, :organization,
                :participating_organization, :codes, :specialties, :locations,
                :healthcare_services, :telecoms, :endpoints

  #-----------------------------------------------------------------------------

  def initialize(organization_affiliation)
    @id = organization_affiliation.id
    @identifiers = organization_affiliation.identifier
    @organization = organization_affiliation.organization
    @participating_organization = organization_affiliation.participatingOrganization
    @codes = organization_affiliation.code
    @specialties = organization_affiliation.specialty
    @locations = organization_affiliation.location
    @healthcare_services = organization_affiliation.healthcareService
    @telecoms = organization_affiliation.telecom
    @endpoints = organization_affiliation.endpoint
    @networks = organization_affiliation.network
  end

  #-----------------------------------------------------------------------------

  def self.query_params
    [
      {
        name: 'Active',
        value: 'active'
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
        value: 'via-intermediary'
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
        name: 'Participating Organization',
        value: 'participating-organization'
      },
      {
        name: 'Phone',
        value: 'phone'
      },
      {
        name: 'Primary Organization',
        value: 'primary-organization'
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
      },
      {
        name: 'Telecom',
        value: 'telecom'
      }
    ]
  end

end
