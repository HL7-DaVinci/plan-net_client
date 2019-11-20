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

 #   uri = URI.parse("https://randomuser.me/api?format=json&gender=#{@gender}")
 #   http = Net::HTTP.new(uri.host, uri.port)
 #   http.use_ssl = true
 #  request = Net::HTTP::Get.new(uri.request_uri)
#  res = http.request(request)
 #   response = JSON.parse(res.body)
 # <a href="https://icon-library.net/icon/female-doctor-icon-9.html" title="Female Doctor Icon #279694"><img src="https://icon-library.net//images/female-doctor-icon/female-doctor-icon-9.jpg" width="350" /></a>
 #  
 # <a href="https://icon-library.net/icon/doctor-icon-png-1.html" title="Doctor Icon Png #418309"><img src="https://icon-library.net//images/doctor-icon-png/doctor-icon-png-1.jpg" width="350" /></a>
 #@photo = response["results"].first["picture"]["large"]
    if gender.eql?("female")
        @photo = "https://icon-library.net//images/female-doctor-icon/female-doctor-icon-9.jpg"
        @phototitle = "Female Doctor Icon #279694"
    else
         @photo = "https://icon-library.net//images/doctor-icon-png/doctor-icon-png-1.jpg"
         @phototitle = "Doctor Icon Png #418309"
    end

  end
end
