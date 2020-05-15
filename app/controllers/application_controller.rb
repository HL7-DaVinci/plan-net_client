# frozen_string_literal: true
require "erb"

################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base

  include ERB::Util
  FHIR.logger.level = Logger::DEBUG

  @@usziptocoord = {}

  def self.get_zip_coords(zipcode)
    @@usziptocoord.size > 0 || @@usziptocoord= JSON.parse( File.read('./app/controllers/usziptocoord.json'))
    @@usziptocoord[zipcode]
  end
  

  # Get the FHIR server url
  def server_url
    params[:server_url] || session[:server_url]
  end

  # Connect the FHIR client with the specified server and save the connection
  # for future requests.

  def connect_to_server
    if server_url.present?
      @client = FHIR::Client.new(server_url)
      @client.use_r4
      @client.additional_headers = { 'Accept-Encoding' => 'identity' }  # 
      @client.set_basic_auth("fhiruser","change-password")
      cookies[:server_url] = server_url
      session[:server_url] = server_url      
     end
   rescue => exception
       err = "Connection failed: Ensure provided url points to a valid FHIR server"
       redirect_to root_path, flash: { error: err }
 
  end

  def update_bundle_links
    session[:next_bundle] = @bundle&.next_link&.url
    session[:previous_bundle] = @bundle&.previous_link&.url
    @next_page_disabled = session[:next_bundle].blank? ? 'disabled' : ''
    @previous_page_disabled = session[:previous_bundle].blank? ? 'disabled' : ''
  end

  #-----------------------------------------------------------------------------

  # Performs pagination on the resource list.
  #
  # Params:
  #   +page+:: which page to get

  def update_page(page)
    case page
    when 'previous'
      @bundle = previous_bundle
    when 'next'
      @bundle = next_bundle
    end
  end

  #-----------------------------------------------------------------------------

  # Retrieves the previous bundle page from the FHIR server.

  def previous_bundle
    url = session[:previous_bundle]

    if url.present?
      @client.parse_reply(FHIR::Bundle, @client.default_format,
                          @client.raw_read_url(url))
    end
  end

  # Retrieves the next bundle page from the FHIR server.

  def next_bundle
    url = session[:next_bundle]

    if url.present?
      @client.parse_reply(FHIR::Bundle, @client.default_format,
                          @client.raw_read_url(url))
    end
  end

  # Turns a query string such as "name=abc&id=123" into a hash like
  # { 'name' => 'abc', 'id' => '123' }
  def query_hash_from_string(query_string)
    query_string.split('&').each_with_object({}) do |string, hash|
      key, value = string.split('=')
      hash[key] = value
    end
  end

  def fetch_payers
    @payers = @client.search(
      FHIR::Organization,
      search: { parameters: { type: 'pay' } }
    )&.resource&.entry&.map do |entry|
      {
        value: entry&.resource&.id,
        name: entry&.resource&.name
      }
    end
  rescue => exception
    redirect_to root_path, flash: { error: 'Please specify a plan network server' }

  end

  # Fetch all plans, and remember their resources, names, and networks
  def fetch_plans (id = nil)
    @plans = []
    parameters = {}
    @networks_by_plan = {}
    parameters[:_profile] = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan' 
    if(id)
      parameters[:_id] = id
    end

    @client.search(
      FHIR::InsurancePlan,
      search: { parameters: parameters }
    )&.resource&.entry&.map do |entry|
      @plans << {
        value: entry&.resource&.id,
        name: entry&.resource&.name
      }
      @networks_by_plan [ entry&.resource&.id] = entry&.resource&.network
    end
   @plans.sort_by! { |hsh| hsh[:name] }
  rescue => exception
    redirect_to root_path, flash: { error: 'Please specify a plan network server' }

  end

# GET /providers/networks or /pharmacies/networks -- perhaps this should be in the networks controller?

def networks
  id = params[:_id]
  fetch_plans(id)
  networks = @networks_by_plan[id]
  network_list = networks.map do |entry|
    {
      value: entry.reference,
      name: entry.display
    }
  end
  render json: network_list
end


  def zip_plus_radius_to_near(params)
    #  Convert zipcode + radius to  lat/long+radius in lat|long|radius|units format
    if params[:zip].present?   # delete zip and radius params and replace with near
      radius = 25
      zip = params[:zip]
      params.delete(:zip)
      if params[:radius].present?
        radius = params[:radius]
        params.delete(:radius)
      end
      # get coordinate
      coords = ApplicationController::get_zip_coords(zip)
      if coords
        near = "#{coords.first}|#{coords.second}|#{radius}|mi"
        @near = near 
        params[:near]=near 
      end
    end
    params
  end

    # Geolocation from MapQuest... obsoleted by USZIPTOCOORDS constant file
    # <<< probably should put Key in CONSTANT and put it somewhere more rational than inline >>>>
def get_zip_coords_from_mapquest(zipcode)
  response = HTTParty.get(
    'http://open.mapquestapi.com/geocoding/v1/address',
    query: {
      key: 'A4F1XOyCcaGmSpgy2bLfQVD5MdJezF0S',
      postalCode: zipcode,
      country: 'USA',
      thumbMaps: false
    }
  )

  # coords = response.deep_symbolize_keys&.dig(:results)&.first&.dig(:locations).first&.dig(:latLng)
  coords = response["results"].first["locations"].first["latLng"]

end


def display_human_name(name)
  result = [name.prefix.join(', '), name.given.join(' '), name.family].join(' ')
  result += ', ' + name.suffix.join(', ') if name.suffix.present?
  result
end

def display_telecom(telecom)
  telecom.system + ': ' + telecom.value
end


def display_address(address)
  "<a href = \"" + "https://www.google.com/maps/search/" + html_escape(address.text) +
   "\" >" +
  address.line.join('<br>') + 
  "<br>#{address.city}, #{address.state} #{format_zip(address.postalCode)}" + 
  "</a>"
end

def preparequerytext(query,klass)
  a = []
  query.each do |key,value| 
    if value.class==Array 
      value.map do  |entry| 
        a << "#{key}=#{entry}"  
      end
    else
      a <<  "#{key}=#{value}"  
    end
  end
  "#{server_url}/#{klass}?" + a.join('&')
end


def format_zip(zip)
  if zip.length > 5
    "#{zip[0..4]}-#{zip[5..-1]}"
  else
    zip
  end
end




 end
