# frozen_string_literal: true

################################################################################
#
# Healthcare Services Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
require 'uri'

class HealthcareServicesController < ApplicationController

  before_action :connect_to_server
  before_action :fetch_plans, only: [:index]

  #-----------------------------------------------------------------------------

  # GET /healthcare_services

  def index
    @params = {}
    @nucc_codes = NUCC_CODES.sort_by { |code| code[:name] }
    @categories = CATEGORIES.sort_by { |category| category[:name] }
    @types = TYPES.sort_by { |type| type[:name] }
  end

  #-----------------------------------------------------------------------------

  # GET /healthcare_services/search

  def search
    if params[:page].present?
      update_page(params[:page])
    else
      base_params = {
        _include: ['OrganizationAffiliation:healthcareService', 'OrganizationAffiliation:location'],
        _profile: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-OrganizationAffiliation'
      }

      query_params = params 
      modifiedparams = zip_plus_radius_to_address(query_params) if query_params 

      query = SEARCH_PARAMS
                .select { |key, _value| modifiedparams[key].present? }
                .each_with_object(base_params) do |(local_key, fhir_key), search_params|
                  search_params[fhir_key] = modifiedparams[local_key]
                end

      @bundle = @client.search(
        FHIR::OrganizationAffiliation,
        search: { parameters: query }
      ).resource

      @search = "<Search String in Returned Bundle is empty>"
      @search = URI.decode(@bundle.link.select { |l| l.relation === "self"}.first.url) if @bundle.link.first 
    end

    update_bundle_links

    render json: {
      healthcare_services: healthcare_services,
      nextPage: @next_page_disabled,
      previousPage: @previous_page_disabled,
  #    searchParams: prepare_query_text(query,"Location")
      searchParams: @search 
    }
  end

  #-----------------------------------------------------------------------------

  # GET /healthcare_services/[id]

  def show
    reply = @client.search(FHIR::HealthcareService,
                           search: { parameters: { _id: params[:id] } })
    bundle = reply.resource
    fhir_healthcare_service = bundle.entry.map(&:resource).first

    @healthcare_service = HealthcareService.new(fhir_healthcare_service) unless
                              fhir_healthcare_service.nil?
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------  
 
  def healthcare_services
    locations.map do |location|
      {
        id: location.id,
        name: location.name,
        telecom: location.telecom.map { |telecom| display_telecom(telecom) },
        address: display_address(location.address)
      }
    end
  end

  #-----------------------------------------------------------------------------

  def org_affiliations
    @org_affiliations ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::OrganizationAffiliation }.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  def org_for_location(location_id)
    org_affiliations.find { |org_aff| org_aff.locations.any? { |location| location.reference.end_with? location_id } }
  end

  #-----------------------------------------------------------------------------

  def locations
    @locations ||= @bundle.entry.select { |entry| entry.resource.instance_of? FHIR::Location }.map(&:resource)
  end

  #-----------------------------------------------------------------------------

  def display_telecom(telecom)
    telecom.system + ': ' + telecom.value
  end

  #-----------------------------------------------------------------------------

  def format_zip(zip)
    if zip.length > 5
      "#{zip[0..4]}-#{zip[5..-1]}"
    else
      zip
    end
  end

  #-----------------------------------------------------------------------------

  SEARCH_PARAMS = {
    network: 'network',
    category: 'healthcareService.service-category', 
    type: 'healthcareService.service-type',
    specialty: 'specialty',
    address: 'location.address',
    city: 'location.address-city',
    name: 'healthcareService.name'
  }.freeze

  #-----------------------------------------------------------------------------

  TYPES = [
    { value: '1', name: 'Adoption/Permanent Care Info/Support' },
    { value: '3', name: 'Aged Care Information/Referral' },
    { value: '8', name: 'Home Care/Housekeeping Assistance' },
    { value: '9', name: 'Home Maintenance and Repair' },
    { value: '10', name: 'Personal Alarms/Alerts' },
    { value: '11', name: 'Personal Care for Older Persons' },
    { value: '21', name: 'Hydrotherapy' },
    { value: '26', name: 'Meditation' },
    { value: '31', name: 'Relaxation Therapy' },
    { value: '33', name: 'Western Herbal Medicine' },
    { value: '34', name: 'Family Day care' },
    { value: '36', name: 'Kindergarten Inclusion Support' },
    { value: '42', name: 'Parenting/Family Support/Education' },
    { value: '51', name: 'Blood Donation' },
    { value: '55', name: 'Health Advocacy/Liaison Service' },
    { value: '67', name: 'Sexual Health' },
    { value: '68', name: 'Speech Pathology/Therapy' },
    { value: '69', name: 'Bereavement Counselling' },
    { value: '70', name: 'Crisis Counselling' },
    { value: '71', name: 'Family Counselling/Therapy' },
    { value: '72', name: 'Family Violence Counselling' },
    { value: '75', name: 'Genetic Counselling' },
    { value: '76', name: 'Health Counselling' },
    { value: '78', name: 'Problem Gambling Counselling' },
    { value: '79', name: 'Relationship Counselling' },
    { value: '80', name: 'Sexual Assault Counselling' },
    { value: '81', name: 'Trauma Counselling' },
    { value: '82', name: 'Victims of Crime Counselling' },
    { value: '96', name: 'Disability Advocacy' },
    { value: '97', name: 'Disability Aids & Equipment' },
    { value: '99', name: 'Disability Day Programs/Activities' },
    { value: '102', name: 'Disability Supported Accommodation' },
    { value: '103', name: 'Early Childhood Intervention' },
    { value: '105', name: 'Drug and/or Alcohol Counselling' },
    { value: '106', name: 'Drug/Alcohol Information/Referral' },
    { value: '107', name: 'Needle & Syringe Exchange' },
    { value: '108', name: 'Non-resid. Alcohol/Drug Treatment' },
    { value: '111', name: 'Residential Alcohol/Drug Treatment' },
    { value: '118', name: 'Employment Placement and/or Support' },
    { value: '119', name: 'Vocational Rehabilitation' },
    { value: '126', name: 'Crisis/Emergency Accommodation' },
    { value: '127', name: 'Homelessness Support' },
    { value: '128', name: 'Housing Information/Referral' },
    { value: '130', name: 'Interpreting/Multilingual Service' },
    { value: '134', name: 'Mental Health Advocacy' },
    { value: '146', name: 'Physical Activity Programs' },
    { value: '147', name: 'Physical Fitness Testing' },
    { value: '224', name: 'Support Groups' },
    { value: '230', name: 'Patient Transport' },
    { value: '233', name: 'Abuse' },
    { value: '238', name: 'Adult Day Programs' },
    { value: '245', name: 'Aids' },
    { value: '275', name: 'Cancer Support' },
    { value: '284', name: 'Child Care' },
    { value: '296', name: 'Companion Visiting' },
    { value: '301', name: 'Contraception Inform' },
    { value: '308', name: 'Crisis Assessment And Treatment Services' },
    { value: '309', name: 'Crisis Assistance' },
    { value: '310', name: 'Crisis Refuge' },
    { value: '316', name: 'Depression' },
    { value: '317', name: 'Detoxification' },
    { value: '323', name: 'Divorce' },
    { value: '328', name: 'Eating Disorder' },
    { value: '331', name: 'Employment And Training' },
    { value: '344', name: 'Food' },
    { value: '345', name: 'Food Vouchers' },
    { value: '352', name: 'Grief Counselling' },
    { value: '366', name: 'Household Items' },
    { value: '400', name: 'Pain' },
    { value: '409', name: 'Postnatal' },
    { value: '411', name: 'Pregnancy Tests' },
    { value: '427', name: 'Rent Assistance' },
    { value: '429', name: 'Residential Respite' },
    { value: '440', name: 'Sexual Issues' },
    { value: '446', name: 'Speech Therapist' },
    { value: '459', name: 'Tenancy Advice' },
    { value: '468', name: 'Vocational Guidance' },
    { value: '470', name: 'Welfare Assistance' },
    { value: '488', name: 'Diabetes Educator' },
    { value: '494', name: 'Youth Services' },
    { value: '495', name: 'Youth Health' },
    { value: '501', name: 'Cancer Services' },
    { value: '513', name: 'Cancer Support Groups' },
    { value: '530', name: 'Disability Care Transport' },
    { value: '531', name: 'Aged Care Transport' },
    { value: '532', name: 'Diabetes Education' },
    { value: '534', name: 'Young Adult Diabetes' },
    { value: '535', name: 'Pulmonary Rehabilitation' },
    { value: '537', name: 'Medication Reviews' },
    { value: '539', name: 'Telephone Help Line' },
    { value: '546', name: 'Veterans Services' },
    { value: '548', name: 'Food Relief/Food/Meals' },
    { value: '552', name: 'Drug and/or Alcohol Support Groups' },
    { value: '554', name: 'Chronic Disease Management' },
    { value: '559', name: "Women's Health" },
    { value: '560', name: "Men's Health" },
    { value: '565', name: 'Youth Drop In/Assistance/Support' },
    { value: '569', name: 'Migrant Health Clinic' },
    { value: '570', name: 'Refugee Health Clinic' },
    { value: '571', name: 'Aboriginal Health Clinic' },
    { value: '614', name: 'Development-Life Skills' },
    { value: '628', name: 'Vehicle modifications' }
  ].freeze

  #-----------------------------------------------------------------------------

  CATEGORIES = [
    { value: 'Behavioral', name: 'Behavioral Health Services' },
    { value: 'Dental', name: 'Dental Services' },
    { value: 'DME', name: 'DME/Medical Supplies' },
    { value: 'Emergency', name: 'Emergency' },
    { value: 'Group', name: 'Medical Group' },
    { value: 'Home', name: 'Home Health' },
    { value: 'Hospital', name: 'Hospital' },
    { value: 'Laboratory', name: 'Laboratory' },
    { value: 'Other', name: 'Other' },
    { value: 'Outpatient', name: 'Clinic or Outpatient Facility' },
    { value: 'Provider', name: 'Medical Provider' },
    { value: 'Pharmacy', name: 'Pharmacy' },
    { value: 'Transport', name: 'Transportation' },
    { value: 'Urgent', name: 'Urgent Care' },
    { value: 'Vision', name: 'Vision' }
  ].freeze

end
