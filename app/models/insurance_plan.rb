# frozen_string_literal: true

################################################################################
#
# InsurancePlan Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class InsurancePlan < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :status, :type, :name, :plan_alias, :owned_by,
                :administered_by, :coverage_areas, :contacts, :endpoints,
                :networks

  #-----------------------------------------------------------------------------

  def initialize(insurance_plan)
    @id = insurance_plan.id
    @status = insurance_plan.status
    @type = insurance_plan.type
    @name = insurance_plan.name
    @plan_alias = insurance_plan.alias
    @owned_by = insurance_plan.ownedBy
    @administered_by = insurance_plan.administeredBy
    @coverage_areas = insurance_plan.coverageArea
    @contacts = insurance_plan.contact
    @endpoints = insurance_plan.endpoint
    @networks = insurance_plan.network
  end

  #-----------------------------------------------------------------------------

  def self.query_params
    [
      {
        name: 'Administered By',
        value: 'administered-by'
      },
      {
        name: 'Coverage Area',
        value: 'coverage-area'
      },
      {
        name: 'Coverage Benefit Type',
        value: 'coverage-benefit-type'
      },
      {
        name: 'Coverage Limit Value',
        value: 'coverage-limit-value'
      },
      {
        name: 'Coverage Network',
        value: 'coverage-network'
      },
      {
        name: 'Coverage Type',
        value: 'coverage-type'
      },
      {
        name: 'Endpoint',
        value: 'endpoint'
      },
      {
        name: 'General Cost Group Size',
        value: 'general-cost-groupsize'
      },
      {
        name: 'General Cost Type',
        value: 'general-cost-type'
      },
      {
        name: 'General Cost Value',
        value: 'general-cost-value'
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
        name: 'Name',
        value: 'name:contains'
      },
      {
        name: 'Network',
        value: 'network'
      },
      {
        name: 'Owned By',
        value: 'owned-by'
      },
      {
        name: 'Plan Coverage Area',
        value: 'plan-coverage-area'
      },
      {
        name: 'Plan Identifier',
        value: 'plan-identifier'
      },
      {
        name: 'Plan Network',
        value: 'plan-network'
      },
      {
        name: 'Plan Type',
        value: 'plan-type'
      },
      {
        name: 'Specific Cost Benefit Type',
        value: 'specific-cost-benefit-type'
      },
      {
        name: 'Specific Cost Category',
        value: 'specific-cost-category'
      },
      {
        name: 'Specific Cost Type',
        value: 'specific-cost-type'
      },
      {
        name: 'Specific Cost Value',
        value: 'specific-cost-value'
      },
      {
        name: 'Status',
        value: 'status'
      },
      {
        name: 'Type',
        value: 'type'
      }
    ]
  end

end
