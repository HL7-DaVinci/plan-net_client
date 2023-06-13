# frozen_string_literal: true

################################################################################
#
# PractitionerRole Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PractitionerRole < Resource
  
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :new_patient, :period, :practitioner, :organization, :code,
                :specialties, :locations, :healthcare_services, :telecoms,
                :available_times, :not_availables, :availability_exceptions,
                :endpoints

  #-----------------------------------------------------------------------------

  def initialize(practitioner_role)
    @id = practitioner_role.id
    @period = practitioner_role.period
    @practitioner = practitioner_role.practitioner
    @organization = practitioner_role.organization
    @code = practitioner_role.code
    @specialties = practitioner_role.specialty
    @locations = practitioner_role.location
    @healthcare_services = practitioner_role.healthcareService
    @telecoms = practitioner_role.telecom
    @available_times = practitioner_role.availableTime
    @not_availables = practitioner_role.notAvailable
    @availability_exceptions = practitioner_role.availabilityExceptions
    @endpoints = practitioner_role.endpoint
    @new_patient = resource.new_patient
  end

  #-----------------------------------------------------------------------------

  def self.query_params
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
        name: 'practitionerrole-network',
        value: 'practitionerrole-network'
      },
      {
        name: 'practitionerrole-new-patient',
        value: 'practitionerrole-new-patient'
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
