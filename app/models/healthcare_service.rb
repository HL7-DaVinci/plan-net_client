# frozen_string_literal: true

################################################################################
#
# HealthcareService Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class HealthcareService < Resource

  include ActiveModel::Model

  attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier,
                :active, :provided_by, :categories, :type, :specialties,
                :locations, :name, :comment, :telecoms, :coverage_areas,
                :service_provision_codes, :eligibilities, :programs,
                :characteristics, :communications, :referral_methods,
                :appointment_required, :available_times, :not_availables,
                :availability_exceptions, :endpoints

  #-----------------------------------------------------------------------------

  def initialize(healthcare_service)
    @id                       = healthcare_service.id
    @provided_by              = healthcare_service.providedBy
    @categories               = healthcare_service.category
    @type                     = healthcare_service.type
    @specialties              = healthcare_service.specialty
    @locations                = healthcare_service.location
    @name                     = healthcare_service.name
    @comment                  = healthcare_service.comment
    @telecoms                 = healthcare_service.telecom
    @coverage_areas           = healthcare_service.coverageArea
    @service_provision_codes  = healthcare_service.serviceProvisionCode
    @eligibilities            = healthcare_service.eligibility
    @programs                 = healthcare_service.program
    @characteristics          = healthcare_service.characteristic
    @communications           = healthcare_service.communication
    @referral_methods         = healthcare_service.referralMethod
    @appointment_required     = healthcare_service.appointmentRequired
    @available_times          = healthcare_service.availableTime
    @not_availables           = healthcare_service.notAvailable
    @availability_exceptions  = healthcare_service.availabilityExceptions
    @endpoints                = healthcare_service.endpoint
  end

  #-----------------------------------------------------------------------------

  def self.search_params
    SEARCH_PARAMS
  end

  #-----------------------------------------------------------------------------

  def self.types
    TYPES
  end

  #-----------------------------------------------------------------------------

  def self.categories
    CATEGORIES
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

  SEARCH_PARAMS = {
    #network: '_has:providedBy:organizationaffiliation:network',
    organization: 'organization.name',
    category: 'service-category', 
    type: 'service-type',
    specialty: 'specialty',
    address: 'location.address',
    city: 'location.address-city',
    zipcode: 'location.address-postalcode',
    name: 'name'
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
    { value: '308', name: 'Crisis Assessment An' },
    { value: '309', name: 'Crisis Assistance' },
    { value: '310', name: 'Crisis Refuge' },
    { value: '316', name: 'Depression' },
    { value: '317', name: 'Detoxification' },
    { value: '323', name: 'Divorce' },
    { value: '328', name: 'Eating Disorder' },
    { value: '331', name: 'Employment And Train' },
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
    { value: '532', name: 'Diabetes Education s' },
    { value: '534', name: 'Young Adult Diabetes' },
    { value: '535', name: 'Pulmonary Rehabilita' },
    { value: '537', name: 'Medication Reviews' },
    { value: '539', name: 'Telephone Help Line' },
    { value: '546', name: 'Veterans Services' },
    { value: '548', name: 'Food Relief/Food/Meals' },
    { value: '552', name: 'Drug and/or Alcohol Support Groups' },
    { value: '554', name: 'Chronic Disease Management' },
    { value: '559', name: 'Womens Health' },
    { value: '560', name: 'Mens Health' },
    { value: '565', name: 'Youth Drop In/Assistance/Support' },
    { value: '569', name: 'Migrant Health Clinic' },
    { value: '570', name: 'Refugee Health Clinic' },
    { value: '571', name: 'Aboriginal Health Clinic' },
    { value: '614', name: 'Development-Life Skills' },
    { value: '628', name: 'Vehicle modifications' }  ].freeze

  #-----------------------------------------------------------------------------

  CATEGORIES = [
    { value: 'behav', name: 'Behavioral Health' },
    { value: 'dent', name: 'Dental' },
    { value: 'dme', name: 'DME/Medical Supplies' },
    { value: 'emerg', name: 'Emergency care' },
    { value: 'group', name: 'Medical Group' },
    { value: 'home', name: 'Home Health' },
    { value: 'hosp', name: 'Hospital' },
    { value: 'lab', name: 'Laboratory' },
    { value: 'other', name: 'Other' },
    { value: 'outpat', name: 'Clinic or Outpatient Facility' },
    { value: 'prov', name: 'Medical Provider' },
    { value: 'pharm', name: 'Pharmacy' },
    { value: 'trans', name: 'Transporation' },
    { value: 'urg', name: 'Urgent Care' },
    { value: 'vis', name: 'Vision' }
  ].freeze

end
