# frozen_string_literal: true

################################################################################
#
# Location Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Location < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :operational_status, :name, :aliases, :description,
                :mode, :type, :telecoms, :address, :physical_type, :position,
                :managing_organization, :part_of, :hours_of_operations,
                :availability_exceptions, :endpoints, :checked

  #-----------------------------------------------------------------------------

  def initialize(location)
    @checked                  = false 
    @id                       = location.id
    @operational_status       = location.operationalStatus
    @name                     = location.name
    @aliases                  = location.alias
    @description              = location.description
    @mode                     = location.mode
    @type                     = location.type
    @telecoms                 = location.telecom
    @address                  = location.address
    @physical_type            = location.physicalType
    @position                 = location.position
    @managing_organization    = location.managingOrganization
    @part_of                  = location.partOf
    @hours_of_operations      = location.hoursOfOperation
    @availability_exceptions  = location.availabilityExceptions
    @endpoints                = location.endpoint
  end

  #-----------------------------------------------------------------------------

  def self.search_params 
    SEARCH_PARAMS
  end

  #-----------------------------------------------------------------------------

  def self.query_params
    [
      {
        name: 'ID',
        value: '_id'
      },
      { 
        name: 'Name',
        value: 'name:contains'
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
        name: 'Available Days (mon,tues...sun)',
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
        name: 'Endpoint (identifier)',
        value: 'Endpoint'
      },
      {
        name: 'Identifier',
        value: 'identifier'
      },
      {
        name: 'Intermediary (identifier)',
        value: 'via-intermediary'
      },
      {
        name: 'Identifier Assigner (identifier)',
        value: 'identifier-assigner'
      },
      {
        name: 'New Patient Network (identifier)',
        value: 'new-patient-network'
      },
      {
        name: 'Radius (in miles from center of zipcode)',
        value: 'radius'
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
        name: 'Organization (identifier)',
        value: 'organization'
      },
      {
        name: 'Part of (identifier)',
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
        name: 'Type (try OUTPHARM)',
        value: 'type'
      },
      {
        name: 'Use',
        value: 'address-use'
      }
    ]
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

  SEARCH_PARAMS = {
    role:     '_has:OrganizationAffiliation:location:role',
    network: '_has:OrganizationAffiliation:location:network',
    specialty: '_has:OrganizationAffiliation:location:specialty',
    address: 'address',
    city: 'address-city:contains',
    zipcode: 'address-postalcode:contains',
    name: 'name:contains'
  }.freeze


end
