# frozen_string_literal: true

################################################################################
#
# Organization Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Organization < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :name, :telecoms, :addresses, :contacts

  #-----------------------------------------------------------------------------

  def initialize(organization)
    @id = organization.id
    @name = organization.name
    @telecoms = organization.telecom
    @addresses = organization.address
    @contacts = organization.contact
  end
end
