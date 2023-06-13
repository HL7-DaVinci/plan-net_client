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

  # Test data now includes links to networks.    
  # We only handle the case where an insurance plan has one cost sharing plan, and the network is at the global level.
  # For a plan with multiple cost sharing plans, each with its own networks, this will fail.
  def plan_networks (id)
    @network_list = @client.search(
      FHIR::InsurancePlan,
      search: { 
        parameters: {
      #    type: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan',
          _id: "#{id}"
        } 
      }
    )&.resource&.entry&.network.map do |network|
      #binding.pry 
      {
        value: network.reference,
        name: network.display
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
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle && @bundle.link.first 
    end

    update_bundle_links

    @query_params = InsurancePlan.query_params
    @insurance_plans = []
    @insurance_plans = @bundle.entry.map(&:resource) if @bundle 
  
  end

  #-----------------------------------------------------------------------------

  # GET /insurance_plans/[id]

  def show
    reply = @client.read(FHIR::InsurancePlan, params[:id])
    fhir_insurance_plan = reply.resource
    @insurance_plan = InsurancePlan.new(fhir_insurance_plan) unless fhir_insurance_plan.nil?
  end

end
