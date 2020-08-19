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
                :active, :name, :telecoms, :addresses, :gender, :birthDate,
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
end
