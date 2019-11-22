# frozen_string_literal: true

################################################################################
#
# Network Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Network < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :name, :telecoms, :addresses, :contacts, :partOf, :ownedBy , :type

  #-----------------------------------------------------------------------------

  def initialize(network)
    @id = network.id
    @name = network.name
    @telecoms = network.telecom
    @addresses = network.address
    @contacts = network.contact
    @partOf = network.partOf 
    @type = network.type 
    # @ownedBy = network.ownedBy  -- broken
  end
end
