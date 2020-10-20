# frozen_string_literal: true

################################################################################
#
# Insurance Plans Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class InsurancePlansController < ApplicationController

  before_action :connect_to_server, only: [:index, :show]

  #-----------------------------------------------------------------------------

  # GET /insurance_plans/networks
  # The current test data doesn't link insurance plans to networks as of 11/8...
  # probably need to rectify that, or fake it by linkages.

  def plan_networks (id)
    @network_list = @client.search(
      FHIR::Organization,
      search: { 
        parameters: {
      #    type: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network',
          partof: "Organization/#{id}",
          type: 'ntwk'
        } 
      }
    )&.resource&.entry&.map do |entry|
      {
        value: entry&.resource&.id,
        name: entry&.resource&.name
      }
    end
  end

  #-----------------------------------------------------------------------------

  # GET /insurance_plans
  
  def index
    if params[:page].present?
      update_page(params[:page])
    else
      if params[:query_string].present?
        parameters = query_hash_from_string(params[:query_string])
        reply = @client.search(
          FHIR::InsurancePlan,
          search: {
            parameters: parameters.merge(
    #          _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan'
            )
          }
        )
      else
        reply = @client.search(
          FHIR::InsurancePlan,
          search: {
            parameters: {
   #           _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan'
            }
          }
        )
      end

      @bundle = reply.resource
      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end

    update_bundle_links

    @query_params = InsurancePlan.query_params
    @insurance_plans = @bundle.entry.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  # GET /insurance_plans/[id]

  def show
    reply = @client.search(FHIR::InsurancePlan,
                           search: { parameters: { _id: params[:id] } })
    bundle = reply.resource
    fhir_insurnace_plan = bundle.entry.map(&:resource).first

    @insurance_plan = InsurancePlan.new(fhir_insurnace_plan) unless fhir_insurnace_plan.nil?
    # plan_networks (params[:id])
  end

end
