# frozen_string_literal: true

################################################################################
#
# Location Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Location < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :operational_status, :name, :aliases, :description,
                :mode, :type, :telecoms, :address, :physical_type, :position,
                :managing_organization, :part_of, :hours_of_operations,
                :availability_exceptions, :endpoints

  #-----------------------------------------------------------------------------

  def initialize(location)
    @id = location.id
    @operational_status = location.operationalStatus
    @name = location.name
    @aliases = location.alias
    @description = location.description
    @mode = location.mode
    @type = location.type
    @telecoms = location.telecom
    @address = location.address
    @physical_type = location.physicalType
    @position = location.position
    @managing_organization = location.managingOrganization
    @part_of = location.partOf
    @hours_of_operations = location.hoursOfOperation
    @availability_exceptions = location.availabilityExceptions
    @endpoints = location.endpoint
  end
end
