# frozen_string_literal: true

################################################################################
#
# Welcome Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class WelcomeController < ApplicationController

  # GET /

  def index
    connect_to_server 
     get_resource_counts
  end

  def get_resource_counts
    begin
			profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Endpoint'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @endpoints = @client.search(FHIR::Endpoint, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-HealthcareService'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @healthCareServices = @client.search(FHIR::HealthcareService, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @insurancePlans = @client.search(FHIR::InsurancePlan, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @networks = @client.search(FHIR::Organization, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @organizations = @client.search(FHIR::Organization, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-OrganizationAffiliation'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @organizationAffiliations = @client.search(FHIR::OrganizationAffiliation, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Practitioner'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @practitioners = @client.search(FHIR::Practitioner, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-PractitionerRole'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @practitionerRoles = @client.search(FHIR::PractitionerRole, search: search ).resource.total
      profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
			search = { parameters: { _profile: profile, _summary: "count" } }
      @locations = @client.search(FHIR::Location, search: search ).resource.total     

		rescue => exception
      @endpoints = 0
      @healthCareServices = 0
      @insurancePlans = 0
      @locations = 0
      @networks = 0
      @organizations = 0
      @organizationAffiliations = 0
      @practitioners = 0
      @practitionerRoles = 0
  
		end

  end
end
