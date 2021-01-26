# frozen_string_literal: true

################################################################################
#
# Organization Affiliations Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class OrganizationAffiliationsController < ApplicationController
  
  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /organization_affiliations

  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(FHIR::OrganizationAffiliation,
                               search: { parameters: parameters })
      else
        reply = @client.search(FHIR::OrganizationAffiliation)
      end
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(
          FHIR::OrganizationAffiliation,
          search: {
            parameters: parameters.merge(
        #      _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-OrganizationAffiliation'
            )
          }
        )
      else
        reply = @client.search(
          FHIR::OrganizationAffiliation,
          search: {
            parameters: {
         #     _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-OrganizationAffiliation'
            }
          }
        )
      end
      
      @bundle = reply.resource
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end
    
    update_bundle_links

    @query_params = OrganizationAffiliation.query_params
    @organization_affiliations = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /organization_affiliations/[id]

  def show
    reply = @client.search(FHIR::OrganizationAffiliation,
                           search: { parameters: { id: params[:id] } })

reply = @client.read(FHIR::OrganizationAffiliation, params[:id])
fhir_organization_affiliation = reply.resource
@organization_affiliation = OrganizationAffiliation.new(fhir_organization_affiliation) unless fhir_organization_affiliation.nil?                       
  end

end
