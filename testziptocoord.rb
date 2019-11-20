
require "json"
require 'httparty'
require 'pry'

zipcode = 20854
    response = HTTParty.get(
       'http://open.mapquestapi.com/geocoding/v1/address',
       query: {
         key: 'A4F1XOyCcaGmSpgy2bLfQVD5MdJezF0S',
         postalCode: zipcode,
         country: 'USA',
         thumbMaps: false
       }
     )
     binding.pry
     # coords = response.deep_symbolize_keys&.dig(:results)&.first&.dig(:locations).first&.dig(:latLng)
     coords = response["results"].first["locations"].first["latLng"]
     {
       x: coords[:lng],
       y: coords[:lat]
     }
     puts coords

   binding.pry

   response = HTTParty.get(
    'https://davinci-plan-net-ri.logicahealth.org/fhir/HealthcareService',
       query: {
        "location.near" => "42|-71|25|km"
       }
    )

    binding.pry
    jresponse = JSON.parse(response.body)
   