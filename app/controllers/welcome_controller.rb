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

  #-----------------------------------------------------------------------------

  def get_resource_counts
    begin
      @endpoints = 0
      @healthCareServices = 0
      @insurancePlans = 0
      @locations = 0
      @networks = 0
      @organizations = 0
      @organizationAffiliations = 0
      @practitioners = 0
      @practitionerRoles = 0
  
		 	#profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Endpoint'
      search = { parameters: { _summary: "count" } }
      results = @client.search(FHIR::Endpoint, search: search )
      @endpoints = results.resource.total  unless results.resource == nil
  
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-HealthcareService'
      search = { parameters: {_summary: "count" } }
      results = @client.search(FHIR::HealthcareService, search: search )
      @healthCareServices = results.resource.total unless results.resource == nil
  
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan'
      search = { parameters: {  _summary: "count" } }
      results = @client.search(FHIR::InsurancePlan, search: search )
      @insurancePlans = results.resource.total unless results.resource == nil
   
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
      # filter by organizaton types that fit Plan-Net Network
      search = { parameters: {  _summary: "count" , type: "ntwk"} }
      results = @client.search(FHIR::Organization, search: search ) 
      @networks = results.resource.total unless results.resource == nil
  
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
      # filter by organizaton types that fit Plan-Net Organization
      search = { parameters: {  _summary: "count", type: 'fac,bus,prvgrp,payer,atyprv' } }
      results = @client.search(FHIR::Organization, search: search )
      @organizations = results.resource.total unless results.resource == nil
   
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-OrganizationAffiliation'
      search = { parameters: {  _summary: "count" } }
      results = @client.search(FHIR::OrganizationAffiliation, search: search )
      @organizationAffiliations = results.resource.total unless results.resource == nil
    
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Practitioner'
      search = { parameters: {  _summary: "count" } }
      results = @client.search(FHIR::Practitioner, search: search )
      @practitioners = results.resource.total unless results.resource == nil
    
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-PractitionerRole'
      search = { parameters: {  _summary: "count" } }
      results = @client.search(FHIR::PractitionerRole, search: search )
      @practitionerRoles = results.resource.total unless results.resource == nil
   
      #profile = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location'
      search = { parameters: {  _summary: "count" } }
      results = @client.search(FHIR::Location, search: search )    
      @locations = results.resource.total unless results.resource == nil
  
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
