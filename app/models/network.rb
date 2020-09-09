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

  #-----------------------------------------------------------------------------

  def self.query_params
    [
      {
        name: 'Active',
        value: 'active'
      },
      {
        name: 'Address',
        value: 'address'
      },
      {
        name: 'City',
        value: 'address-city'
      },
      {
        name: 'Country',
        value: 'address-country'
      },
      {
        name: 'Coverage Area',
        value: 'coverage-area'
      },
      {
        name: 'Endpoint',
        value: 'endpoint'
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
        name: 'Identifier Assigner',
        value: 'identifier-assigner'
      },
      {
        name: 'Name',
        value: 'name:contains'
      },
      {
        name: 'Part Of',
        value: 'partof'
      },
      {
        name: 'Postal Code',
        value: 'address-postalcode'
      },
      {
        name: 'State',
        value: 'address-state'
      },
      {
        name: 'Type',
        value: 'type'
      }
    ]
  end

end
