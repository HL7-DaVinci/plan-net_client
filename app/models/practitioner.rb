# frozen_string_literal: true

################################################################################
#
# Practitioner Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Practitioner < Resource
  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :new_patient, :name, :telecoms, :addresses, :gender, :birthDate,
                :photo, :qualifications, :communications

  #-----------------------------------------------------------------------------

  def initialize(practitioner)
    @id = practitioner.id
    @name = practitioner.name
    @telecoms = practitioner.telecom
    @addresses = practitioner.address
    @gender = practitioner.gender
    @birthDate = practitioner.birthDate
    @photo = practitioner.photo
    @qualifications = practitioner.qualification
    @communications = practitioner.communication
    
    if gender.eql?("female")
        @photo = "female-doctor-icon-9.jpg"
        @phototitle = "Female Doctor Icon #279694"
    else
         @photo = "doctor-icon-png-1.jpg"
         @phototitle = "Doctor Icon Png #418309"
    end
  end

  #-----------------------------------------------------------------------------

  def self.query_params
    [
      {
        name: 'Endpoint',
        value: 'endpoint'
      },
      {
        name: 'Family name',
        value: 'family:contains'
      },
      {
        name: 'Given name',
        value: 'given:contains'
      },
      {
        name: 'Identfier Assigner',
        value: 'identifier-assigner'
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
        name: 'Phonetic',
        value: 'phonetic'
      },
      {
        name: 'Qualification Code',
        value: 'qualification-code'
      },
      {
        name: 'Qualification Issuer',
        value: 'qualification-issuer'
      },
      {
        name: 'Qualification Period',
        value: 'qualification-period'
      },
      {
        name: 'Qualification Status',
        value: 'qualification-status'
      },
      {
        name: 'Qualification Where Valid Code',
        value: 'qualification-wherevalid-code'
      },
      {
        name: 'Qualification Where Valid Location',
        value: 'qualification-wherevalid-location'
      }
    ]
  end

end
