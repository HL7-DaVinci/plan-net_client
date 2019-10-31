# frozen_string_literal: true

################################################################################
#
# HealthcareService Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class HealthcareService < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :provided_by, :categories, :type, :specialties,
                :locations, :name, :comment, :telecoms, :coverage_areas,
                :service_provision_codes, :eligibilities, :programs,
                :characteristics, :communications, :referral_methods,
                :appointment_required, :available_times, :not_availables,
                :availability_exceptions, :endpoints

  #-----------------------------------------------------------------------------

  def initialize(healthcare_service)
    @id = healthcare_service.id
    @provided_by = healthcare_service.providedBy
    @categories = healthcare_service.category
    @type = healthcare_service.type
    @specialties = healthcare_service.specialty
    @locations = healthcare_service.location
    @name = healthcare_service.name
    @comment = healthcare_service.comment
    @telecoms = healthcare_service.telecom
    @coverage_areas = healthcare_service.coverageArea
    @service_provision_codes = healthcare_service.serviceProvisionCode
    @eligibilities = healthcare_service.eligibility
    @programs = healthcare_service.program
    @characteristics = healthcare_service.characteristic
    @communications = healthcare_service.communication
    @referral_methods = healthcare_service.referralMethod
    @appointment_required = healthcare_service.appointmentRequired
    @available_times = healthcare_service.availableTime
    @not_availables = healthcare_service.notAvailable
    @availability_exceptions = healthcare_service.availabilityExceptions
    @endpoints = healthcare_service.endpoint
  end
end
