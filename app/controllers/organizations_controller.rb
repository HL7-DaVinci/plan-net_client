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
    typecodes = 'fac,bus,prvgrp,payer,atyprv' 
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])

        reply = @client.search(
          FHIR::Organization,
          search: {
            parameters: parameters.merge(
       #       _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
               type:      typecodes         
            )
          }
        )
      else
        reply = @client.search(
          FHIR::Organization,
          search: {
            parameters: {
        #      _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Organization'
              type:      typecodes    
            }
          }
        )
      end
    
      @bundle = reply.resource
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end

    update_bundle_links

    @query_params = Organization.query_params
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

end
