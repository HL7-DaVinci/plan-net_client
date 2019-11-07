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
                :active, :name, :telecoms, :addresses, :contacts, :geolocation, :type

  #-----------------------------------------------------------------------------

  def initialize(organization)
    @id = organization.id
    @name = organization.name
    @telecoms = organization.telecom
    @addresses = organization.address
    @contacts = organization.contact
    @type = organization.type 
    parse_address(organization)

  end

  private
  # There a bunch of extensions.   We will start with the ones that are of direct interest and go from there.
  # addresses[0].extension[0].extension[0].valueDecimal
  def parse_address(organization)
    #start with the geolocation extension on address
    lat = 0;
    long = 0;
    @geolocation=[]
    organization.address.each do |address|
      extensions = address.extension
     if extensions.present?
          extensions.each do |extension|
              if extension.url.include?('geolocation')
                 extension.extension.each do |latlong|
                    if latlong.url.include?('latitude')
                       lat = latlong.valueDecimal
                    end
                    if latlong.url.include?('longitude')
                      long = latlong.valueDecimal
                    end
                end
                @geolocation << {latitude: lat, longitude: long }
            end
        end
    end
  end
end
end
