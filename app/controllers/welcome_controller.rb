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
    setexportpoll(nil)
  end

  # Poll for comletion of $export operation and, if complete,  display the paths to the data for export

  def export
    binding.pry 
    connect_to_server 
    exportpoll_url = session[:exportpoll]
    binding.pry 
    if exportpoll_url   #exportpoll
      response = RestClient::Request.new( :method => :get, :url => exportpoll_url, :prefer => "respond-async").execute 
      
      # should expect code=200 with Content-Location header with the absolute URL of an endpoint
      # then should hit the endpoint until a code = 200 is received
      # 500 error
      # 202 in progress with X-Progress header
      # 200 complete
     case response.code
      when 200
          results = JSON.parse(response.to_str)
          binding.pry 
          @request = results["request"]
          @outputs = results["output"]
          @requiresToken = results["requiresAccessToken"]
          setexportpoll(nil)
        when 202
          results = JSON.parse(response.to_str)
          progress = results[:X-Progress]
          binding.pry 
          @request = results["request"]
          @outputs = []
          @requiresToken = "In progress:   #{progress}... try again later"
      else # 500 or anything else
          @request = response.request.url  + "  failed with code = " + response.code.to_s
          @requiresToken = "Failed"
          @outputs= []
          setexportpoll(nil)
        end
    else   #export
      response = RestClient::Request.new( :method => :get, :url => server_url + "/$export", :prefer => "respond-async").execute 
      # should expect code=202 with Content-Location header with the absolute URL of an endpoint
      # then should hit the endpoint until a code = 200 is received
      binding.pry 
      if response.code == 200   # request submitted successfully
        results = JSON.parse(response.to_str)
        binding.pry 
        # exportpollurl = results[:headers][:Content-Location]
        exportpollurl = server_url + "/$export"     # temporary
        setexportpoll(exportpollurl)
        @request = response.request.url  + "  successfuly requested"
        @requiresToken = "Requested"
        @outputs= []
        binding.pry 
      else
        @request = response.request.url  + "  failed with code = " + response.code.to_s
        @requiresToken = "Failed"
        @outputs= []
        setexportpoll(nil)
      end
    end
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
      setexportpoll(nil)
		end

  end
  def setexportpoll(url)
    if url
      @label = "ExportPoll"
    else
      @label = "Export"
    end
    session[:exportpoll] = url
  end
end
