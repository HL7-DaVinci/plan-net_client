# frozen_string_literal: true

################################################################################
#
# Abstract Resource Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Resource
  # Initialize common FHIR resource data elements

  def initialize(resource)
    @id = resource.id
    @meta = resource.meta
    @implicit_rules = resource.implicitRules
    @language = resource.language
    @text = resource.text
    @identifier = resource.identifier
    @active = resource.active,
    @new_patient = resource.new_patient
  end

  #-----------------------------------------------------------------------------

  # Adds a warning message to the specified resource

  def warning(message)
    @warnings = [] unless @warnings.present?
    @warnings.append(message)
  end

  #-----------------------------------------------------------------------------

  # Adds an error message to the specified resource

  def error(message)
    @errors = [] unless @errors.present?
    @errors.append(message)
  end
end
