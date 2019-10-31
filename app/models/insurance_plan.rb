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
end
