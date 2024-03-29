# frozen_string_literal: true
require "erb"
require 'pry'

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

  #-----------------------------------------------------------------------------

  # Get the FHIR server url
  def server_url
    url = (params[:server_url] || session[:server_url])
    url = url.strip if url 
  end

  #-----------------------------------------------------------------------------

  def setup_dalli
    unless Rails.env.production?
      options = { :namespace => "plan-net", :compress => true }
      @dalli_client = Dalli::Client.new('localhost:11211', options)
    end
  end

  #-----------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------

  # Retrieves the next bundle page from the FHIR server.

  def next_bundle
    url = session[:next_bundle]

    if url.present?
      @client.parse_reply(FHIR::Bundle, @client.default_format,
                          @client.raw_read_url(url))
    end
  end

  #-----------------------------------------------------------------------------

  # Turns a query string such as "name=abc&id=123" into a hash like
  # { 'name' => 'abc', 'id' => '123' }
  def query_hash_from_string(query_string)
    query_string.split('&').each_with_object({}) do |string, hash|
      key, value = string.split('=')
      hash[key] = value
    end
  end

  #-----------------------------------------------------------------------------

  def fetch_payers
    # binding.pry 
    @payers = @client.search(
      FHIR::Organization,
      search: { parameters: { type: 'payer' } }
    ).resource.entry.map do |entry|
      {
        value: entry.resource.id,
        name: entry.resource.name
      }
    end
    
  rescue => exception
    redirect_to root_path, flash: { error: 'Please specify a plan network server (fetch_payers)' }
  end

  #-----------------------------------------------------------------------------

  # Fetch all plans, and remember their resources, names, and networks

  def fetch_plans (id = nil)
    @plans = []
    parameters = {}
    @networks_by_plan = {}

    #parameters[:_profile] = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan' 
    parameters[:_count] = 100
    if (id.present?)
      parameters[:_id] = id
    end

    insurance_plans = @client.search(FHIR::InsurancePlan,
                                      search: { parameters: parameters })
    if good_response(insurance_plans.response[:code]) 
      insurance_plans.resource.entry.map do |entry|
        if entry.resource.id.present? && entry.resource.name.present?
          @plans << {
            value: entry.resource.id,
            name: entry.resource.name
          }
          @networks_by_plan[entry.resource.id] = entry.resource.network
        end
      end

      @plans.sort_by! { |hsh| hsh[:name] }
    else
      redirect_to root_path, 
          flash: { error: "Could not retrieve insurance plans from the server (fetch_plans, " + 
                        insurance_plans.response[:code].to_s + ")" }
    end
  end

  #-----------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------

  def zip_plus_radius_to_address(params)
    #  Convert zipcode + radius to address='zipcode list'
    if params[:zip].present?   # delete zip and radius params and replace with address
      zip = params[:zip]
      params.delete(:zip)
      radius = 5 # default
      if params[:radius].present?
        radius = params[:radius].to_i
        params.delete(:radius)
      end
      params[:zipcode] = Zipcode.zipcodes_within(radius, zip).join(',')
    end
    params
  end

  #-----------------------------------------------------------------------------

  def display_human_name(name)
    result = [name.prefix.join(', '), name.given.join(' '), name.family].join(' ')
    result += ', ' + name.suffix.join(', ') if name.suffix.present?
    result
  end

  #-----------------------------------------------------------------------------

  def display_telecom(telecom)
    telecom.system + ': ' + telecom.value
  end

  #-----------------------------------------------------------------------------

  def display_address(address)
    if address.present?
      "<a href = \"" + "https://www.google.com/maps/search/" + html_escape(address.text) +
       "\" >" +
      address.line.join('<br>') + 
      "<br>#{address.city}, #{address.state} #{format_zip(address.postalCode)}" + 
      "</a>"
    end
  end

  #-----------------------------------------------------------------------------

  def prepare_query_text(query,klass)
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

  #-----------------------------------------------------------------------------

  def format_zip(zip)
    if zip.length > 5
      "#{zip[0..4]}-#{zip[5..-1]}"
    else
      zip
    end
  end

  #-----------------------------------------------------------------------------

  def good_response(response)
    response >= 200 && response < 300
  end

  #-----------------------------------------------------------------------------
  
  NON_INDIVIDUAL_SPECIALTIES = [
    { value: '251300000X', name: 'Local Education Agency (LEA)' },
    { value: '251B00000X', name: 'Case Management Agency' },
    { value: '251C00000X', name: 'Developmentally Disabled Services Day Training Agency' },
    { value: '251E00000X', name: 'Home Health Agency' },
    { value: '251F00000X', name: 'Home Infusion Agency' },
    { value: '251G00000X', name: 'Community Based Hospice Care Agency' },
    { value: '251J00000X', name: 'Nursing Care Agency' },
    { value: '251K00000X', name: 'Public Health or Welfare Agency' },
    { value: '251S00000X', name: 'Community/Behavioral Health Agency' },
    { value: '251T00000X', name: 'PACE Provider Organization' },
    { value: '251V00000X', name: 'Voluntary or Charitable Agency' },
    { value: '251X00000X', name: 'Supports Brokerage Agency' },
    { value: '252Y00000X', name: 'Early Intervention Provider Agency' },
    { value: '253J00000X', name: 'Foster Care Agency' },
    { value: '253Z00000X', name: 'In Home Supportive Care Agency' },
    { value: '261Q00000X', name: 'Clinic/Center' },
    { value: '261QA0005X', name: 'Ambulatory Family Planning Facility' },
    { value: '261QA0006X', name: 'Ambulatory Fertility Facility' },
    { value: '261QA0600X', name: 'Adult Day Care Clinic/Center' },
    { value: '261QA0900X', name: 'Amputee Clinic/Center' },
    { value: '261QA1903X', name: 'Ambulatory Surgical Clinic/Center' },
    { value: '261QA3000X', name: 'Augmentative Communication Clinic/Center' },
    { value: '261QB0400X', name: 'Birthing Clinic/Center' },
    { value: '261QC0050X', name: 'Critical Access Hospital Clinic/Center' },
    { value: '261QC1500X', name: 'Community Health Clinic/Center' },
    { value: '261QC1800X', name: 'Corporate Health Clinic/Center' },
    { value: '261QD0000X', name: 'Dental Clinic/Center' },
    { value: '261QD1600X', name: 'Developmental Disabilities Clinic/Center' },
    { value: '261QE0002X', name: 'Emergency Care Clinic/Center' },
    { value: '261QE0700X', name: 'End-Stage Renal Disease (ESRD) Treatment Clinic/Center' },
    { value: '261QE0800X', name: 'Endoscopy Clinic/Center' },
    { value: '261QF0050X', name: 'Non-Surgical Family Planning Clinic/Center' },
    { value: '261QF0400X', name: 'Federally Qualified Health Center (FQHC)' },
    { value: '261QG0250X', name: 'Genetics Clinic/Center' },
    { value: '261QH0100X', name: 'Health Service Clinic/Center' },
    { value: '261QH0700X', name: 'Hearing and Speech Clinic/Center' },
    { value: '261QI0500X', name: 'Infusion Therapy Clinic/Center' },
    { value: '261QL0400X', name: 'Lithotripsy Clinic/Center' },
    { value: '261QM0801X', name: 'Mental Health Clinic/Center (Including Community Mental Health Center)' },
    { value: '261QM0850X', name: 'Adult Mental Health Clinic/Center' },
    { value: '261QM0855X', name: 'Adolescent and Children Mental Health Clinic/Center' },
    { value: '261QM1000X', name: 'Migrant Health Clinic/Center' },
    { value: '261QM1100X', name: 'Military/U.S. Coast Guard Outpatient Clinic/Center' },
    { value: '261QM1101X', name: 'Military and U.S. Coast Guard Ambulatory Procedure Clinic/Center' },
    { value: '261QM1102X', name: 'Military Outpatient Operational (Transportable) Component Clinic/Center' },
    { value: '261QM1103X', name: 'Military Ambulatory Procedure Visits Operational (Transportable) Clinic/Center' },
    { value: '261QM1200X', name: 'Magnetic Resonance Imaging (MRI) Clinic/Center' },
    { value: '261QM1300X', name: 'Multi-Specialty Clinic/Center' },
    { value: '261QM2500X', name: 'Medical Specialty Clinic/Center' },
    { value: '261QM2800X', name: 'Methadone Clinic' },
    { value: '261QM3000X', name: 'Medically Fragile Infants and Children Day Care' },
    { value: '261QP0904X', name: 'Federal Public Health Clinic/Center' },
    { value: '261QP0905X', name: 'State or Local Public Health Clinic/Center' },
    { value: '261QP1100X', name: 'Podiatric Clinic/Center' },
    { value: '261QP2000X', name: 'Physical Therapy Clinic/Center' },
    { value: '261QP2300X', name: 'Primary Care Clinic/Center' },
    { value: '261QP2400X', name: 'Prison Health Clinic/Center' },
    { value: '261QP3300X', name: 'Pain Clinic/Center' },
    { value: '261QR0200X', name: 'Radiology Clinic/Center' },
    { value: '261QR0206X', name: 'Mammography Clinic/Center' },
    { value: '261QR0207X', name: 'Mobile Mammography Clinic/Center' },
    { value: '261QR0208X', name: 'Mobile Radiology Clinic/Center' },
    { value: '261QR0400X', name: 'Rehabilitation Clinic/Center' },
    { value: '261QR0401X', name: 'Comprehensive Outpatient Rehabilitation Facility (CORF)' },
    { value: '261QR0404X', name: 'Cardiac Rehabilitation Clinic/Center' },
    { value: '261QR0405X', name: 'Substance Use Disorder Rehabilitation Clinic/Center' },
    { value: '261QR0800X', name: 'Recovery Care Clinic/Center' },
    { value: '261QR1100X', name: 'Research Clinic/Center' },
    { value: '261QR1300X', name: 'Rural Health Clinic/Center' },
    { value: '261QS0112X', name: 'Oral and Maxillofacial Surgery Clinic/Center' },
    { value: '261QS0132X', name: 'Ophthalmologic Surgery Clinic/Center' },
    { value: '261QS1000X', name: 'Student Health Clinic/Center' },
    { value: '261QS1200X', name: 'Sleep Disorder Diagnostic Clinic/Center' },
    { value: '261QU0200X', name: 'Urgent Care Clinic/Center' },
    { value: '261QV0200X', name: 'VA Clinic/Center' },
    { value: '261QX0100X', name: 'Occupational Medicine Clinic/Center' },
    { value: '261QX0200X', name: 'Oncology Clinic/Center' },
    { value: '261QX0203X', name: 'Radiation Oncology Clinic/Center' },
    { value: '273100000X', name: 'Epilepsy Hospital Unit' },
    { value: '273R00000X', name: 'Psychiatric Hospital Unit' },
    { value: '273Y00000X', name: 'Rehabilitation Hospital Unit' },
    { value: '275N00000X', name: 'Medicare Defined Swing Bed Hospital Unit' },
    { value: '276400000X', name: 'Substance Use Disorder Rehabilitation Hospital Unit' },
    { value: '281P00000X', name: 'Chronic Disease Hospital' },
    { value: '281PC2000X', name: 'Childrens Chronic Disease Hospital' },
    { value: '282E00000X', name: 'Long Term Care Hospital' },
    { value: '282J00000X', name: 'Religious Nonmedical Health Care Institution' },
    { value: '282N00000X', name: 'General Acute Care Hospital' },
    { value: '282NC0060X', name: 'Critical Access Hospital' },
    { value: '282NC2000X', name: 'Childrens Hospital' },
    { value: '282NR1301X', name: 'Rural Acute Care Hospital' },
    { value: '282NW0100X', name: 'Womens Hospital' },
    { value: '283Q00000X', name: 'Psychiatric Hospital' },
    { value: '283X00000X', name: 'Rehabilitation Hospital' },
    { value: '283XC2000X', name: 'Childrens Rehabilitation Hospital' },
    { value: '284300000X', name: 'Special Hospital' },
    { value: '286500000X', name: 'Military Hospital' },
    { value: '2865M2000X', name: 'Military General Acute Care Hospital' },
    { value: '2865X1600X', name: 'Operational (Transportable) Military General Acute Care Hospital' },
    { value: '291900000X', name: 'Military Clinical Medical Laboratory' },
    { value: '291U00000X', name: 'Clinical Medical Laboratory' },
    { value: '292200000X', name: 'Dental Laboratory' },
    { value: '293D00000X', name: 'Physiological Laboratory' },
    { value: '302F00000X', name: 'Exclusive Provider Organization' },
    { value: '302R00000X', name: 'Health Maintenance Organization' },
    { value: '305R00000X', name: 'Preferred Provider Organization' },
    { value: '305S00000X', name: 'Point of Service' },
    { value: '310400000X', name: 'Assisted Living Facility' },
    { value: '3104A0625X', name: 'Assisted Living Facility (Mental Illness)' },
    { value: '3104A0630X', name: 'Assisted Living Facility (Behavioral Disturbances)' },
    { value: '310500000X', name: 'Mental Illness Intermediate Care Facility' },
    { value: '311500000X', name: 'Alzheimer Center (Dementia Center)' },
    { value: '311Z00000X', name: 'Custodial Care Facility' },
    { value: '311ZA0620X', name: 'Adult Care Home Facility' },
    { value: '313M00000X', name: 'Nursing Facility/Intermediate Care Facility' },
    { value: '314000000X', name: 'Skilled Nursing Facility' },
    { value: '3140N1450X', name: 'Pediatric Skilled Nursing Facility' },
    { value: '315D00000X', name: 'Inpatient Hospice' },
    { value: '315P00000X', name: 'Intellectual Disabilities Intermediate Care Facility' },
    { value: '174200000X', name: 'Meals Provider' },
    { value: '177F00000X', name: 'Lodging Provider' },
    { value: '320600000X', name: 'Intellectual and/or Developmental Disabilities Residential Treatment Facility' },
    { value: '320700000X', name: 'Physical Disabilities Residential Treatment Facility' },
    { value: '320800000X', name: 'Mental Illness Community Based Residential Treatment Facility' },
    { value: '320900000X', name: 'Intellectual and/or Developmental Disabilities Community Based Residential Treatment Facility' },
    { value: '322D00000X', name: 'Emotionally Disturbed Childrens Residential Treatment Facility' },
    { value: '323P00000X', name: 'Psychiatric Residential Treatment Facility' },
    { value: '324500000X', name: 'Substance Abuse Rehabilitation Facility' },
    { value: '3245S0500X', name: 'Childrens Substance Abuse Rehabilitation Facility' },
    { value: '385H00000X', name: 'Respite Care' },
    { value: '385HR2050X', name: 'Respite Care Camp' },
    { value: '385HR2055X', name: 'Child Mental Illness Respite Care' },
    { value: '385HR2060X', name: 'Child Intellectual and/or Developmental Disabilities Respite Care' },
    { value: '385HR2065X', name: 'Child Physical Disabilities Respite Care' },
    { value: '331L00000X', name: 'Blood Bank' },
    { value: '332000000X', name: 'Military/U.S. Coast Guard Pharmacy' },
    { value: '332100000X', name: 'Department of Veterans Affairs (VA) Pharmacy' },
    { value: '332800000X', name: 'Indian Health Service/Tribal/Urban Indian Health (I/T/U) Pharmacy' },
    { value: '332900000X', name: 'Non-Pharmacy Dispensing Site' },
    { value: '332B00000X', name: 'Durable Medical Equipment & Medical Supplies' },
    { value: '332BC3200X', name: 'Customized Equipment (DME)' },
    { value: '332BD1200X', name: 'Dialysis Equipment & Supplies (DME)' },
    { value: '332BN1400X', name: 'Nursing Facility Supplies (DME)' },
    { value: '332BP3500X', name: 'Parenteral & Enteral Nutrition Supplies (DME)' },
    { value: '332BX2000X', name: 'Oxygen Equipment & Supplies (DME)' },
    { value: '332G00000X', name: 'Eye Bank' },
    { value: '332H00000X', name: 'Eyewear Supplier' },
    { value: '332S00000X', name: 'Hearing Aid Equipment' },
    { value: '332U00000X', name: 'Home Delivered Meals' },
    { value: '333300000X', name: 'Emergency Response System Companies' },
    { value: '333600000X', name: 'Pharmacy' },
    { value: '3336C0002X', name: 'Clinic Pharmacy' },
    { value: '3336C0003X', name: 'Community/Retail Pharmacy' },
    { value: '3336C0004X', name: 'Compounding Pharmacy' },
    { value: '3336H0001X', name: 'Home Infusion Therapy Pharmacy' },
    { value: '3336I0012X', name: 'Institutional Pharmacy' },
    { value: '3336L0003X', name: 'Long Term Care Pharmacy' },
    { value: '3336M0002X', name: 'Mail Order Pharmacy' },
    { value: '3336M0003X', name: 'Managed Care Organization Pharmacy' },
    { value: '3336N0007X', name: 'Nuclear Pharmacy' },
    { value: '3336S0011X', name: 'Specialty Pharmacy' },
    { value: '335E00000X', name: 'Prosthetic/Orthotic Supplier' },
    { value: '335G00000X', name: 'Medical Foods Supplier' },
    { value: '335U00000X', name: 'Organ Procurement Organization' },
    { value: '335V00000X', name: 'Portable X-ray and/or Other Portable Diagnostic Imaging Supplier' },
    { value: '341600000X', name: 'Ambulance' },
    { value: '3416A0800X', name: 'Air Ambulance' },
    { value: '3416L0300X', name: 'Land Ambulance' },
    { value: '3416S0300X', name: 'Water Ambulance' },
    { value: '341800000X', name: 'Military/U.S. Coast Guard Transport,' },
    { value: '3418M1110X', name: 'Military or U.S. Coast Guard Ground Transport Ambulance' },
    { value: '3418M1120X', name: 'Military or U.S. Coast Guard Air Transport Ambulance' },
    { value: '3418M1130X', name: 'Military or U.S. Coast Guard Water Transport Ambulance' },
    { value: '343800000X', name: 'Secured Medical Transport (VAN)' },
    { value: '343900000X', name: 'Non-emergency Medical Transport (VAN)' },
    { value: '344600000X', name: 'Taxi' },
    { value: '344800000X', name: 'Air Carrier' },
    { value: '347B00000X', name: 'Bus' },
    { value: '347C00000X', name: 'Private Vehicle' },
    { value: '347D00000X', name: 'Train' },
    { value: '347E00000X', name: 'Transportation Broker' }
  ].freeze 

  INDIVIDUAL_AND_GROUP_SPECIALTIES = [
    { value: '101200000X', name: 'Drama Therapist' },
    { value: '101Y00000X', name: 'Counselor' },
    { value: '101YA0400X', name: 'Addiction (Substance Use Disorder) Counselor' },
    { value: '101YM0800X', name: 'Mental Health Counselor' },
    { value: '101YP1600X', name: 'Pastoral Counselor' },
    { value: '101YP2500X', name: 'Professional Counselor' },
    { value: '101YS0200X', name: 'School Counselor' },
    { value: '102L00000X', name: 'Psychoanalyst' },
    { value: '102X00000X', name: 'Poetry Therapist' },
    { value: '103G00000X', name: 'Clinical Neuropsychologist' },
    { value: '103K00000X', name: 'Behavioral Analyst' },
    { value: '103T00000X', name: 'Psychologist' },
    { value: '103TA0400X', name: 'Addiction (Substance Use Disorder) Psychologist' },
    { value: '103TA0700X', name: 'Adult Development & Aging Psychologist' },
    { value: '103TB0200X', name: 'Cognitive & Behavioral Psychologist' },
    { value: '103TC0700X', name: 'Clinical Psychologist' },
    { value: '103TC1900X', name: 'Counseling Psychologist' },
    { value: '103TC2200X', name: 'Clinical Child & Adolescent Psychologist' },
    { value: '103TE1100X', name: 'Exercise & Sports Psychologist' },
    { value: '103TF0000X', name: 'Family Psychologist' },
    { value: '103TF0200X', name: 'Forensic Psychologist' },
    { value: '103TH0004X', name: 'Health Psychologist' },
    { value: '103TH0100X', name: 'Health Service Psychologist' },
    { value: '103TM1800X', name: 'Intellectual & Developmental Disabilities Psychologist' },
    { value: '103TP0016X', name: 'Prescribing (Medical) Psychologist' },
    { value: '103TP0814X', name: 'Psychoanalysis Psychologist' },
    { value: '103TP2701X', name: 'Group Psychotherapy Psychologist' },
    { value: '103TR0400X', name: 'Rehabilitation Psychologist' },
    { value: '103TS0200X', name: 'School Psychologist' },
    { value: '104100000X', name: 'Social Worker' },
    { value: '1041C0700X', name: 'Clinical Social Worker' },
    { value: '1041S0200X', name: 'School Social Worker' },
    { value: '106E00000X', name: 'Assistant Behavior Analyst' },
    { value: '106H00000X', name: 'Marriage & Family Therapist' },
    { value: '106S00000X', name: 'Behavior Technician' },
    { value: '111N00000X', name: 'Chiropractor' },
    { value: '111NI0013X', name: 'Independent Medical Examiner Chiropractor' },
    { value: '111NI0900X', name: 'Internist Chiropractor' },
    { value: '111NN0400X', name: 'Neurology Chiropractor' },
    { value: '111NN1001X', name: 'Nutrition Chiropractor' },
    { value: '111NP0017X', name: 'Pediatric Chiropractor' },
    { value: '111NR0200X', name: 'Radiology Chiropractor' },
    { value: '111NR0400X', name: 'Rehabilitation Chiropractor' },
    { value: '111NS0005X', name: 'Sports Physician Chiropractor' },
    { value: '111NT0100X', name: 'Thermography Chiropractor' },
    { value: '111NX0100X', name: 'Occupational Health Chiropractor' },
    { value: '111NX0800X', name: 'Orthopedic Chiropractor' },
    { value: '122300000X', name: 'Dentist' },
    { value: '1223D0001X', name: 'Public Health Dentist' },
    { value: '1223D0004X', name: 'Dentist Anesthesiologist' },
    { value: '1223E0200X', name: 'Endodontist' },
    { value: '1223G0001X', name: 'General Practice Dentistry' },
    { value: '1223P0106X', name: 'Oral and Maxillofacial Pathology Dentist' },
    { value: '1223P0221X', name: 'Pediatric Dentist' },
    { value: '1223P0300X', name: 'Periodontist' },
    { value: '1223P0700X', name: 'Prosthodontist' },
    { value: '1223S0112X', name: 'Oral and Maxillofacial Surgery (Dentist)' },
    { value: '1223X0008X', name: 'Oral and Maxillofacial Radiology Dentist' },
    { value: '1223X0400X', name: 'Orthodontics and Dentofacial Orthopedic Dentist' },
    { value: '1223X2210X', name: 'Orofacial Pain Dentist' },
    { value: '122400000X', name: 'Denturist' },
    { value: '124Q00000X', name: 'Dental Hygienist' },
    { value: '125J00000X', name: 'Dental Therapist' },
    { value: '125K00000X', name: 'Advanced Practice Dental Therapist' },
    { value: '125Q00000X', name: 'Oral Medicinist' },
    { value: '126800000X', name: 'Dental Assistant' },
    { value: '126900000X', name: 'Dental Laboratory Technician' },
    { value: '132700000X', name: 'Dietary Manager' },
    { value: '133N00000X', name: 'Nutritionist' },
    { value: '133NN1002X', name: 'Nutrition Education Nutritionist' },
    { value: '133V00000X', name: 'Registered Dietitian' },
    { value: '133VN1004X', name: 'Pediatric Nutrition Registered Dietitian' },
    { value: '133VN1005X', name: 'Renal Nutrition Registered Dietitian' },
    { value: '133VN1006X', name: 'Metabolic Nutrition Registered Dietitian' },
    { value: '133VN1101X', name: 'Gerontological Nutrition Registered Dietitian' },
    { value: '133VN1201X', name: 'Obesity and Weight Management Nutrition Registered Dietitian' },
    { value: '133VN1301X', name: 'Oncology Nutrition Registered Dietitian' },
    { value: '133VN1401X', name: 'Pediatric Critical Care Nutrition Registered Dietitian' },
    { value: '133VN1501X', name: 'Sports Dietetics Nutrition Registered Dietitian' },
    { value: '136A00000X', name: 'Registered Dietetic Technician' },
    { value: '146D00000X', name: 'Personal Emergency Response Attendant' },
    { value: '146L00000X', name: 'Paramedic' },
    { value: '146M00000X', name: 'Intermediate Emergency Medical Technician' },
    { value: '146N00000X', name: 'Basic Emergency Medical Technician' },
    { value: '152W00000X', name: 'Optometrist' },
    { value: '152WC0802X', name: 'Corneal and Contact Management Optometrist' },
    { value: '152WL0500X', name: 'Low Vision Rehabilitation Optometrist' },
    { value: '152WP0200X', name: 'Pediatric Optometrist' },
    { value: '152WS0006X', name: 'Sports Vision Optometrist' },
    { value: '152WV0400X', name: 'Vision Therapy Optometrist' },
    { value: '152WX0102X', name: 'Occupational Vision Optometrist' },
    { value: '156F00000X', name: 'Technician/Technologist' },
    { value: '156FC0800X', name: 'Contact Lens Technician/Technologist' },
    { value: '156FC0801X', name: 'Contact Lens Fitter' },
    { value: '156FX1100X', name: 'Ophthalmic Technician/Technologist' },
    { value: '156FX1101X', name: 'Ophthalmic Assistant' },
    { value: '156FX1201X', name: 'Optometric Assistant Technician' },
    { value: '156FX1202X', name: 'Optometric Technician' },
    { value: '156FX1700X', name: 'Ocularist' },
    { value: '156FX1800X', name: 'Optician' },
    { value: '156FX1900X', name: 'Orthoptist' },
    { value: '163W00000X', name: 'Registered Nurse' },
    { value: '163WA0400X', name: 'Addiction (Substance Use Disorder) Registered Nurse' },
    { value: '163WA2000X', name: 'Administrator Registered Nurse' },
    { value: '163WC0200X', name: 'Critical Care Medicine Registered Nurse' },
    { value: '163WC0400X', name: 'Case Management Registered Nurse' },
    { value: '163WC1400X', name: 'College Health Registered Nurse' },
    { value: '163WC1500X', name: 'Community Health Registered Nurse' },
    { value: '163WC1600X', name: 'Continuing Education/Staff Development Registered Nurse' },
    { value: '163WC2100X', name: 'Continence Care Registered Nurse' },
    { value: '163WC3500X', name: 'Cardiac Rehabilitation Registered Nurse' },
    { value: '163WD0400X', name: 'Diabetes Educator Registered Nurse' },
    { value: '163WD1100X', name: 'Peritoneal Dialysis Registered Nurse' },
    { value: '163WE0003X', name: 'Emergency Registered Nurse' },
    { value: '163WE0900X', name: 'Enterostomal Therapy Registered Nurse' },
    { value: '163WF0300X', name: 'Flight Registered Nurse' },
    { value: '163WG0000X', name: 'General Practice Registered Nurse' },
    { value: '163WG0100X', name: 'Gastroenterology Registered Nurse' },
    { value: '163WG0600X', name: 'Gerontology Registered Nurse' },
    { value: '163WH0200X', name: 'Home Health Registered Nurse' },
    { value: '163WH0500X', name: 'Hemodialysis Registered Nurse' },
    { value: '163WH1000X', name: 'Hospice Registered Nurse' },
    { value: '163WI0500X', name: 'Infusion Therapy Registered Nurse' },
    { value: '163WI0600X', name: 'Infection Control Registered Nurse' },
    { value: '163WL0100X', name: 'Lactation Consultant (Registered Nurse)' },
    { value: '163WM0102X', name: 'Maternal Newborn Registered Nurse' },
    { value: '163WM0705X', name: 'Medical-Surgical Registered Nurse' },
    { value: '163WM1400X', name: 'Nurse Massage Therapist (NMT)' },
    { value: '163WN0002X', name: 'Neonatal Intensive Care Registered Nurse' },
    { value: '163WN0003X', name: 'Low-Risk Neonatal Registered Nurse' },
    { value: '163WN0300X', name: 'Nephrology Registered Nurse' },
    { value: '163WN0800X', name: 'Neuroscience Registered Nurse' },
    { value: '163WN1003X', name: 'Nutrition Support Registered Nurse' },
    { value: '163WP0000X', name: 'Pain Management Registered Nurse' },
    { value: '163WP0200X', name: 'Pediatric Registered Nurse' },
    { value: '163WP0218X', name: 'Pediatric Oncology Registered Nurse' },
    { value: '163WP0807X', name: 'Child & Adolescent Psychiatric/Mental Health Registered Nurse' },
    { value: '163WP0808X', name: 'Psychiatric/Mental Health Registered Nurse' },
    { value: '163WP0809X', name: 'Adult Psychiatric/Mental Health Registered Nurse' },
    { value: '163WP1700X', name: 'Perinatal Registered Nurse' },
    { value: '163WP2201X', name: 'Ambulatory Care Registered Nurse' },
    { value: '163WR0006X', name: 'Registered Nurse First Assistant' },
    { value: '163WR0400X', name: 'Rehabilitation Registered Nurse' },
    { value: '163WR1000X', name: 'Reproductive Endocrinology/Infertility Registered Nurse' },
    { value: '163WS0121X', name: 'Plastic Surgery Registered Nurse' },
    { value: '163WS0200X', name: 'School Registered Nurse' },
    { value: '163WU0100X', name: 'Urology Registered Nurse' },
    { value: '163WW0000X', name: 'Wound Care Registered Nurse' },
    { value: '163WW0101X', name: 'Ambulatory Womens Health Care Registered Nurse' },
    { value: '163WX0002X', name: 'High-Risk Obstetric Registered Nurse' },
    { value: '163WX0003X', name: 'Inpatient Obstetric Registered Nurse' },
    { value: '163WX0106X', name: 'Occupational Health Registered Nurse' },
    { value: '163WX0200X', name: 'Oncology Registered Nurse' },
    { value: '163WX0601X', name: 'Otorhinolaryngology & Head-Neck Registered Nurse' },
    { value: '163WX0800X', name: 'Orthopedic Registered Nurse' },
    { value: '163WX1100X', name: 'Ophthalmic Registered Nurse' },
    { value: '163WX1500X', name: 'Ostomy Care Registered Nurse' },
    { value: '164W00000X', name: 'Licensed Practical Nurse' },
    { value: '164X00000X', name: 'Licensed Vocational Nurse' },
    { value: '167G00000X', name: 'Licensed Psychiatric Technician' },
    { value: '170100000X', name: 'Ph.D. Medical Genetics' },
    { value: '170300000X', name: 'Genetic Counselor (M.S.)' },
    { value: '171000000X', name: 'Military Health Care Provider' },
    { value: '1710I1002X', name: 'Independent Duty Corpsman' },
    { value: '1710I1003X', name: 'Independent Duty Medical Technicians' },
    { value: '171400000X', name: 'Health & Wellness Coach' },
    { value: '171100000X', name: 'Acupuncturist' },
    { value: '171M00000X', name: 'Case Manager/Care Coordinator' },
    { value: '171R00000X', name: 'Interpreter' },
    { value: '171W00000X', name: 'Contractor' },
    { value: '171WH0202X', name: 'Home Modifications Contractor' },
    { value: '171WV0202X', name: 'Vehicle Modifications Contractor' },
    { value: '172A00000X', name: 'Driver' },
    { value: '172M00000X', name: 'Mechanotherapist' },
    { value: '172P00000X', name: 'Naprapath' },
    { value: '172V00000X', name: 'Community Health Worker' },
    { value: '173000000X', name: 'Legal Medicine' },
    { value: '173C00000X', name: 'Reflexologist' },
    { value: '173F00000X', name: 'Sleep Specialist (PhD)' },
    { value: '174400000X', name: 'Specialist' },
    { value: '1744G0900X', name: 'Graphics Designer' },
    { value: '1744P3200X', name: 'Prosthetics Case Management' },
    { value: '1744R1102X', name: 'Research Study Specialist' },
    { value: '1744R1103X', name: 'Research Study Abstracter/Coder' },
    { value: '174H00000X', name: 'Health Educator' },
    { value: '174M00000X', name: 'Veterinarian' },
    { value: '174MM1900X', name: 'Medical Research Veterinarian' },
    { value: '174N00000X', name: 'Lactation Consultant (Non-RN)' },
    { value: '174V00000X', name: 'Clinical Ethicist' },
    { value: '175F00000X', name: 'Naturopath' },
    { value: '175L00000X', name: 'Homeopath' },
    { value: '175M00000X', name: 'Lay Midwife' },
    { value: '175T00000X', name: 'Peer Specialist' },
    { value: '176B00000X', name: 'Midwife' },
    { value: '176P00000X', name: 'Funeral Director' },
    { value: '183500000X', name: 'Pharmacist' },
    { value: '1835C0205X', name: 'Critical Care Pharmacist' },
    { value: '1835G0303X', name: 'Geriatric Pharmacist' },
    { value: '1835N0905X', name: 'Nuclear Pharmacist' },
    { value: '1835N1003X', name: 'Nutrition Support Pharmacist' },
    { value: '1835P0018X', name: 'Pharmacist Clinician (PhC)/ Clinical Pharmacy Specialist' },
    { value: '1835P0200X', name: 'Pediatric Pharmacist' },
    { value: '1835P1200X', name: 'Pharmacotherapy Pharmacist' },
    { value: '1835P1300X', name: 'Psychiatric Pharmacist' },
    { value: '1835P2201X', name: 'Ambulatory Care Pharmacist' },
    { value: '1835X0200X', name: 'Oncology Pharmacist' },
    { value: '183700000X', name: 'Pharmacy Technician' },
    { value: '193200000X', name: 'Multi-Specialty Group' },
    { value: '202C00000X', name: 'Independent Medical Examiner Physician' },
    { value: '202K00000X', name: 'Phlebology Physician' },
    { value: '204C00000X', name: 'Sports Medicine (Neuromusculoskeletal Medicine) Physician' },
    { value: '204D00000X', name: 'Neuromusculoskeletal Medicine & OMM Physician' },
    { value: '204E00000X', name: 'Oral & Maxillofacial Surgery (D.M.D.) Physician' },
    { value: '204F00000X', name: 'Transplant Surgery Physician' },
    { value: '204R00000X', name: 'Electrodiagnostic Medicine Physician' },
    { value: '207K00000X', name: 'Allergy & Immunology Physician' },
    { value: '207KA0200X', name: 'Allergy Physician' },
    { value: '207KI0005X', name: 'Clinical & Laboratory Immunology (Allergy & Immunology) Physician' },
    { value: '207L00000X', name: 'Anesthesiology Physician' },
    { value: '207LA0401X', name: 'Addiction Medicine (Anesthesiology) Physician' },
    { value: '207LC0200X', name: 'Critical Care Medicine (Anesthesiology) Physician' },
    { value: '207LH0002X', name: 'Hospice and Palliative Medicine (Anesthesiology) Physician' },
    { value: '207LP2900X', name: 'Pain Medicine (Anesthesiology) Physician' },
    { value: '207LP3000X', name: 'Pediatric Anesthesiology Physician' },
    { value: '207N00000X', name: 'Dermatology Physician' },
    { value: '207ND0101X', name: 'MOHS-Micrographic Surgery Physician' },
    { value: '207ND0900X', name: 'Dermatopathology Physician' },
    { value: '207NI0002X', name: 'Clinical & Laboratory Dermatological Immunology Physician' },
    { value: '207NP0225X', name: 'Pediatric Dermatology Physician' },
    { value: '207NS0135X', name: 'Procedural Dermatology Physician' },
    { value: '207P00000X', name: 'Emergency Medicine Physician' },
    { value: '207PE0004X', name: 'Emergency Medical Services (Emergency Medicine) Physician' },
    { value: '207PE0005X', name: 'Undersea and Hyperbaric Medicine (Emergency Medicine) Physician' },
    { value: '207PH0002X', name: 'Hospice and Palliative Medicine (Emergency Medicine) Physician' },
    { value: '207PP0204X', name: 'Pediatric Emergency Medicine (Emergency Medicine) Physician' },
    { value: '207PS0010X', name: 'Sports Medicine (Emergency Medicine) Physician' },
    { value: '207PT0002X', name: 'Medical Toxicology (Emergency Medicine) Physician' },
    { value: '207Q00000X', name: 'Family Medicine Physician' },
    { value: '207QA0000X', name: 'Adolescent Medicine (Family Medicine) Physician' },
    { value: '207QA0401X', name: 'Addiction Medicine (Family Medicine) Physician' },
    { value: '207QA0505X', name: 'Adult Medicine Physician' },
    { value: '207QB0002X', name: 'Obesity Medicine (Family Medicine) Physician' },
    { value: '207QG0300X', name: 'Geriatric Medicine (Family Medicine) Physician' },
    { value: '207QH0002X', name: 'Hospice and Palliative Medicine (Family Medicine) Physician' },
    { value: '207QS0010X', name: 'Sports Medicine (Family Medicine) Physician' },
    { value: '207QS1201X', name: 'Sleep Medicine (Family Medicine) Physician' },
    { value: '207R00000X', name: 'Internal Medicine Physician' },
    { value: '207RA0000X', name: 'Adolescent Medicine (Internal Medicine) Physician' },
    { value: '207RA0001X', name: 'Advanced Heart Failure and Transplant Cardiology Physician' },
    { value: '207RA0002X', name: 'Adult Congenital Heart Disease Physician' },
    { value: '207RA0201X', name: 'Allergy & Immunology (Internal Medicine) Physician' },
    { value: '207RA0401X', name: 'Addiction Medicine (Internal Medicine) Physician' },
    { value: '207RB0002X', name: 'Obesity Medicine (Internal Medicine) Physician' },
    { value: '207RC0000X', name: 'Cardiovascular Disease Physician' },
    { value: '207RC0001X', name: 'Clinical Cardiac Electrophysiology Physician' },
    { value: '207RC0200X', name: 'Critical Care Medicine (Internal Medicine) Physician' },
    { value: '207RE0101X', name: 'Endocrinology, Diabetes & Metabolism Physician' },
    { value: '207RG0100X', name: 'Gastroenterology Physician' },
    { value: '207RG0300X', name: 'Geriatric Medicine (Internal Medicine) Physician' },
    { value: '207RH0000X', name: 'Hematology (Internal Medicine) Physician' },
    { value: '207RH0002X', name: 'Hospice and Palliative Medicine (Internal Medicine) Physician' },
    { value: '207RH0003X', name: 'Hematology & Oncology Physician' },
    { value: '207RH0005X', name: 'Hypertension Specialist Physician' },
    { value: '207RI0001X', name: 'Clinical & Laboratory Immunology (Internal Medicine) Physician' },
    { value: '207RI0008X', name: 'Hepatology Physician' },
    { value: '207RI0011X', name: 'Interventional Cardiology Physician' },
    { value: '207RI0200X', name: 'Infectious Disease Physician' },
    { value: '207RM1200X', name: 'Magnetic Resonance Imaging (MRI) Internal Medicine Physician' },
    { value: '207RN0300X', name: 'Nephrology Physician' },
    { value: '207RP1001X', name: 'Pulmonary Disease Physician' },
    { value: '207RR0500X', name: 'Rheumatology Physician' },
    { value: '207RS0010X', name: 'Sports Medicine (Internal Medicine) Physician' },
    { value: '207RS0012X', name: 'Sleep Medicine (Internal Medicine) Physician' },
    { value: '207RT0003X', name: 'Transplant Hepatology Physician' },
    { value: '207RX0202X', name: 'Medical Oncology Physician' },
    { value: '207SC0300X', name: 'Clinical Cytogenetics Physician' },
    { value: '207SG0201X', name: 'Clinical Genetics (M.D.) Physician' },
    { value: '207SG0202X', name: 'Clinical Biochemical Genetics Physician' },
    { value: '207SG0203X', name: 'Clinical Molecular Genetics Physician' },
    { value: '207SG0205X', name: 'Ph.D. Medical Genetics Physician' },
    { value: '207SM0001X', name: 'Molecular Genetic Pathology (Medical Genetics) Physician' },
    { value: '207T00000X', name: 'Neurological Surgery Physician' },
    { value: '207U00000X', name: 'Nuclear Medicine Physician' },
    { value: '207UN0901X', name: 'Nuclear Cardiology Physician' },
    { value: '207UN0902X', name: 'Nuclear Imaging & Therapy Physician' },
    { value: '207UN0903X', name: 'In Vivo & In Vitro Nuclear Medicine Physician' },
    { value: '207V00000X', name: 'Obstetrics & Gynecology Physician' },
    { value: '207VB0002X', name: 'Obesity Medicine (Obstetrics & Gynecology) Physician' },
    { value: '207VC0200X', name: 'Critical Care Medicine (Obstetrics & Gynecology) Physician' },
    { value: '207VE0102X', name: 'Reproductive Endocrinology Physician' },
    { value: '207VF0040X', name: 'Female Pelvic Medicine and Reconstructive Surgery (Obstetrics & Gynecology) Physician' },
    { value: '207VG0400X', name: 'Gynecology Physician' },
    { value: '207VH0002X', name: 'Hospice and Palliative Medicine (Obstetrics & Gynecology) Physician' },
    { value: '207VM0101X', name: 'Maternal & Fetal Medicine Physician' },
    { value: '207VX0000X', name: 'Obstetrics Physician' },
    { value: '207VX0201X', name: 'Gynecologic Oncology Physician' },
    { value: '207W00000X', name: 'Ophthalmology Physician' },
    { value: '207WX0009X', name: 'Glaucoma Specialist (Ophthalmology) Physician' },
    { value: '207WX0107X', name: 'Retina Specialist (Ophthalmology) Physician' },
    { value: '207WX0108X', name: 'Uveitis and Ocular Inflammatory Disease (Ophthalmology) Physician' },
    { value: '207WX0109X', name: 'Neuro-ophthalmology Physician' },
    { value: '207WX0110X', name: 'Pediatric Ophthalmology and Strabismus Specialist Physician' },
    { value: '207WX0120X', name: 'Cornea and External Diseases Specialist Physician' },
    { value: '207WX0200X', name: 'Ophthalmic Plastic and Reconstructive Surgery Physician' },
    { value: '207X00000X', name: 'Orthopaedic Surgery Physician' },
    { value: '207XP3100X', name: 'Pediatric Orthopaedic Surgery Physician' },
    { value: '207XS0106X', name: 'Orthopaedic Hand Surgery Physician' },
    { value: '207XS0114X', name: 'Adult Reconstructive Orthopaedic Surgery Physician' },
    { value: '207XS0117X', name: 'Orthopaedic Surgery of the Spine Physician' },
    { value: '207XX0004X', name: 'Orthopaedic Foot and Ankle Surgery Physician' },
    { value: '207XX0005X', name: 'Sports Medicine (Orthopaedic Surgery) Physician' },
    { value: '207XX0801X', name: 'Orthopaedic Trauma Physician' },
    { value: '207Y00000X', name: 'Otolaryngology Physician' },
    { value: '207YP0228X', name: 'Pediatric Otolaryngology Physician' },
    { value: '207YS0012X', name: 'Sleep Medicine (Otolaryngology) Physician' },
    { value: '207YS0123X', name: 'Facial Plastic Surgery Physician' },
    { value: '207YX0007X', name: 'Plastic Surgery within the Head & Neck (Otolaryngology) Physician' },
    { value: '207YX0602X', name: 'Otolaryngic Allergy Physician' },
    { value: '207YX0901X', name: 'Otology & Neurotology Physician' },
    { value: '207YX0905X', name: 'Otolaryngology/Facial Plastic Surgery Physician' },
    { value: '207ZB0001X', name: 'Blood Banking & Transfusion Medicine Physician' },
    { value: '207ZC0006X', name: 'Clinical Pathology Physician' },
    { value: '207ZC0008X', name: 'Clinical Informatics (Pathology) Physician' },
    { value: '207ZC0500X', name: 'Cytopathology Physician' },
    { value: '207ZD0900X', name: 'Dermatopathology (Pathology) Physician' },
    { value: '207ZF0201X', name: 'Forensic Pathology Physician' },
    { value: '207ZH0000X', name: 'Hematology (Pathology) Physician' },
    { value: '207ZI0100X', name: 'Immunopathology Physician' },
    { value: '207ZM0300X', name: 'Medical Microbiology Physician' },
    { value: '207ZN0500X', name: 'Neuropathology Physician' },
    { value: '207ZP0007X', name: 'Molecular Genetic Pathology (Pathology) Physician' },
    { value: '207ZP0101X', name: 'Anatomic Pathology Physician' },
    { value: '207ZP0102X', name: 'Anatomic Pathology & Clinical Pathology Physician' },
    { value: '207ZP0104X', name: 'Chemical Pathology Physician' },
    { value: '207ZP0105X', name: 'Clinical Pathology/Laboratory Medicine Physician' },
    { value: '207ZP0213X', name: 'Pediatric Pathology Physician' },
    { value: '208000000X', name: 'Pediatrics Physician' },
    { value: '2080A0000X', name: 'Pediatric Adolescent Medicine Physician' },
    { value: '2080B0002X', name: 'Pediatric Obesity Medicine Physician' },
    { value: '2080C0008X', name: 'Child Abuse Pediatrics Physician' },
    { value: '2080H0002X', name: 'Pediatric Hospice and Palliative Medicine Physician' },
    { value: '2080I0007X', name: 'Pediatric Clinical & Laboratory Immunology Physician' },
    { value: '2080N0001X', name: 'Neonatal-Perinatal Medicine Physician' },
    { value: '2080P0006X', name: 'Developmental – Behavioral Pediatrics Physician' },
    { value: '2080P0008X', name: 'Pediatric Neurodevelopmental Disabilities Physician' },
    { value: '2080P0201X', name: 'Pediatric Allergy/Immunology Physician' },
    { value: '2080P0202X', name: 'Pediatric Cardiology Physician' },
    { value: '2080P0203X', name: 'Pediatric Critical Care Medicine Physician' },
    { value: '2080P0204X', name: 'Pediatric Emergency Medicine (Pediatrics) Physician' },
    { value: '2080P0205X', name: 'Pediatric Endocrinology Physician' },
    { value: '2080P0206X', name: 'Pediatric Gastroenterology Physician' },
    { value: '2080P0207X', name: 'Pediatric Hematology & Oncology Physician' },
    { value: '2080P0208X', name: 'Pediatric Infectious Diseases Physician' },
    { value: '2080P0210X', name: 'Pediatric Nephrology Physician' },
    { value: '2080P0214X', name: 'Pediatric Pulmonology Physician' },
    { value: '2080P0216X', name: 'Pediatric Rheumatology Physician' },
    { value: '2080S0010X', name: 'Pediatric Sports Medicine Physician' },
    { value: '2080S0012X', name: 'Pediatric Sleep Medicine Physician' },
    { value: '2080T0002X', name: 'Pediatric Medical Toxicology Physician' },
    { value: '2080T0004X', name: 'Pediatric Transplant Hepatology Physician' },
    { value: '208100000X', name: 'Physical Medicine & Rehabilitation Physician' },
    { value: '2081H0002X', name: 'Hospice and Palliative Medicine (Physical Medicine & Rehabilitation) Physician' },
    { value: '2081N0008X', name: 'Neuromuscular Medicine (Physical Medicine & Rehabilitation) Physician' },
    { value: '2081P0004X', name: 'Spinal Cord Injury Medicine Physician' },
    { value: '2081P0010X', name: 'Pediatric Rehabilitation Medicine Physician' },
    { value: '2081P0301X', name: 'Brain Injury Medicine (Physical Medicine & Rehabilitation) Physician' },
    { value: '2081P2900X', name: 'Pain Medicine (Physical Medicine & Rehabilitation) Physician' },
    { value: '2081S0010X', name: 'Sports Medicine (Physical Medicine & Rehabilitation) Physician' },
    { value: '208200000X', name: 'Plastic Surgery Physician' },
    { value: '2082S0099X', name: 'Plastic Surgery Within the Head and Neck (Plastic Surgery) Physician' },
    { value: '2082S0105X', name: 'Surgery of the Hand (Plastic Surgery) Physician' },
    { value: '2083A0100X', name: 'Aerospace Medicine Physician' },
    { value: '2083A0300X', name: 'Addiction Medicine (Preventive Medicine) Physician' },
    { value: '2083B0002X', name: 'Obesity Medicine (Preventive Medicine) Physician' },
    { value: '2083C0008X', name: 'Clinical Informatics Physician' },
    { value: '2083P0011X', name: 'Undersea and Hyperbaric Medicine (Preventive Medicine) Physician' },
    { value: '2083P0500X', name: 'Preventive Medicine/Occupational Environmental Medicine Physician' },
    { value: '2083P0901X', name: 'Public Health & General Preventive Medicine Physician' },
    { value: '2083S0010X', name: 'Sports Medicine (Preventive Medicine) Physician' },
    { value: '2083T0002X', name: 'Medical Toxicology (Preventive Medicine) Physician' },
    { value: '2083X0100X', name: 'Occupational Medicine Physician' },
    { value: '2084A0401X', name: 'Addiction Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084A2900X', name: 'Neurocritical Care Physician' },
    { value: '2084B0002X', name: 'Obesity Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084B0040X', name: 'Behavioral Neurology & Neuropsychiatry Physician' },
    { value: '2084D0003X', name: 'Diagnostic Neuroimaging (Psychiatry & Neurology) Physician' },
    
    { value: '2084F0202X', name: 'Forensic Psychiatry Physician' },
    { value: '2084H0002X', name: 'Hospice and Palliative Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084N0008X', name: 'Neuromuscular Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084N0400X', name: 'Neurology Physician' },
    { value: '2084N0402X', name: 'Neurology with Special Qualifications in Child Neurology Physician' },
    { value: '2084N0600X', name: 'Clinical Neurophysiology Physician' },
    { value: '2084P0005X', name: 'Neurodevelopmental Disabilities Physician' },
    { value: '2084P0015X', name: 'Psychosomatic Medicine Physician' },
    { value: '2084P0301X', name: 'Brain Injury Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084P0800X', name: 'Psychiatry Physician' },
    { value: '2084P0802X', name: 'Addiction Psychiatry Physician' },
    { value: '2084P0804X', name: 'Child & Adolescent Psychiatry Physician' },
    { value: '2084P0805X', name: 'Geriatric Psychiatry Physician' },
    { value: '2084P2900X', name: 'Pain Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084S0010X', name: 'Sports Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084S0012X', name: 'Sleep Medicine (Psychiatry & Neurology) Physician' },
    { value: '2084V0102X', name: 'Vascular Neurology Physician' },
    { value: '2085B0100X', name: 'Body Imaging Physician' },
    { value: '2085D0003X', name: 'Diagnostic Neuroimaging (Radiology) Physician' },
    { value: '2085H0002X', name: 'Hospice and Palliative Medicine (Radiology) Physician' },
    { value: '2085N0700X', name: 'Neuroradiology Physician' },
    { value: '2085N0904X', name: 'Nuclear Radiology Physician' },
    { value: '2085P0229X', name: 'Pediatric Radiology Physician' },
    { value: '2085R0001X', name: 'Radiation Oncology Physician' },
    { value: '2085R0202X', name: 'Diagnostic Radiology Physician' },
    { value: '2085R0203X', name: 'Therapeutic Radiology Physician' },
    { value: '2085R0204X', name: 'Vascular & Interventional Radiology Physician' },
    { value: '2085R0205X', name: 'Radiological Physics Physician' },
    { value: '2085U0001X', name: 'Diagnostic Ultrasound Physician' },
    { value: '208600000X', name: 'Surgery Physician' },
    { value: '2086H0002X', name: 'Hospice and Palliative Medicine (Surgery) Physician' },
    { value: '2086S0102X', name: 'Surgical Critical Care Physician' },
    { value: '2086S0105X', name: 'Surgery of the Hand (Surgery) Physician' },
    { value: '2086S0120X', name: 'Pediatric Surgery Physician' },
    { value: '2086S0122X', name: 'Plastic and Reconstructive Surgery Physician' },
    { value: '2086S0127X', name: 'Trauma Surgery Physician' },
    { value: '2086S0129X', name: 'Vascular Surgery Physician' },
    { value: '2086X0206X', name: 'Surgical Oncology Physician' },
    { value: '208800000X', name: 'Urology Physician' },
    { value: '2088F0040X', name: 'Female Pelvic Medicine and Reconstructive Surgery (Urology) Physician' },
    { value: '2088P0231X', name: 'Pediatric Urology Physician' },
    { value: '208C00000X', name: 'Colon & Rectal Surgery Physician' },
    { value: '208D00000X', name: 'General Practice Physician' },
    { value: '208G00000X', name: 'Thoracic Surgery (Cardiothoracic Vascular Surgery) Physician' },
    { value: '208M00000X', name: 'Hospitalist Physician' },
    { value: '208U00000X', name: 'Clinical Pharmacology Physician' },
    { value: '208VP0000X', name: 'Pain Medicine Physician' },
    { value: '208VP0014X', name: 'Interventional Pain Medicine Physician' },
    { value: '209800000X', name: 'Legal Medicine (M.D./D.O.) Physician' },
    { value: '211D00000X', name: 'Podiatric Assistant' },
    { value: '213E00000X', name: 'Podiatrist' },
    { value: '213EP0504X', name: 'Public Medicine Podiatrist' },
    { value: '213EP1101X', name: 'Primary Podiatric Medicine Podiatrist' },
    { value: '213ER0200X', name: 'Radiology Podiatrist' },
    { value: '213ES0000X', name: 'Sports Medicine Podiatrist' },
    { value: '213ES0103X', name: 'Foot & Ankle Surgery Podiatrist' },
    { value: '213ES0131X', name: 'Foot Surgery Podiatrist' },
    { value: '221700000X', name: 'Art Therapist' },
    { value: '222Q00000X', name: 'Developmental Therapist' },
    { value: '222Z00000X', name: 'Orthotist' },
    { value: '224900000X', name: 'Mastectomy Fitter' },
    { value: '224L00000X', name: 'Pedorthist' },
    { value: '224P00000X', name: 'Prosthetist' },
    { value: '224Y00000X', name: 'Clinical Exercise Physiologist' },
    { value: '224Z00000X', name: 'Occupational Therapy Assistant' },
    { value: '224ZE0001X', name: 'Environmental Modification Occupational Therapy Assistant' },
    { value: '224ZF0002X', name: 'Feeding, Eating & Swallowing Occupational Therapy Assistant' },
    { value: '224ZL0004X', name: 'Low Vision Occupational Therapy Assistant' },
    { value: '224ZR0403X', name: 'Driving and Community Mobility Occupational Therapy Assistant' },
    { value: '225000000X', name: 'Orthotic Fitter' },
    { value: '225100000X', name: 'Physical Therapist' },
    { value: '2251C2600X', name: 'Cardiopulmonary Physical Therapist' },
    { value: '2251E1200X', name: 'Ergonomics Physical Therapist' },
    { value: '2251E1300X', name: 'Clinical Electrophysiology Physical Therapist' },
    { value: '2251G0304X', name: 'Geriatric Physical Therapist' },
    { value: '2251H1200X', name: 'Hand Physical Therapist' },
    { value: '2251H1300X', name: 'Human Factors Physical Therapist' },
    { value: '2251N0400X', name: 'Neurology Physical Therapist' },
    { value: '2251P0200X', name: 'Pediatric Physical Therapist' },
    { value: '2251S0007X', name: 'Sports Physical Therapist' },
    { value: '2251X0800X', name: 'Orthopedic Physical Therapist' },
    { value: '225200000X', name: 'Physical Therapy Assistant' },
    { value: '225400000X', name: 'Rehabilitation Practitioner' },
    { value: '225500000X', name: 'Respiratory/Developmental/Rehabilitative Specialist/Technologist' },
    { value: '2255A2300X', name: 'Athletic Trainer' },
    { value: '2255R0406X', name: 'Blind Rehabilitation Specialist/Technologist' },
    { value: '225600000X', name: 'Dance Therapist' },
    { value: '225700000X', name: 'Massage Therapist' },
    { value: '225800000X', name: 'Recreation Therapist' },
    { value: '225A00000X', name: 'Music Therapist' },
    { value: '225B00000X', name: 'Pulmonary Function Technologist' },
    { value: '225C00000X', name: 'Rehabilitation Counselor' },
    { value: '225CA2400X', name: 'Assistive Technology Practitioner Rehabilitation Counselor' },
    { value: '225CA2500X', name: 'Assistive Technology Supplier Rehabilitation Counselor' },
    { value: '225CX0006X', name: 'Orientation and Mobility Training Rehabilitation Counselor' },
    { value: '225X00000X', name: 'Occupational Therapist' },
    { value: '225XE0001X', name: 'Environmental Modification Occupational Therapist' },
    { value: '225XE1200X', name: 'Ergonomics Occupational Therapist' },
    { value: '225XF0002X', name: 'Feeding, Eating & Swallowing Occupational Therapist' },
    { value: '225XG0600X', name: 'Gerontology Occupational Therapist' },
    { value: '225XH1200X', name: 'Hand Occupational Therapist' },
    { value: '225XH1300X', name: 'Human Factors Occupational Therapist' },
    { value: '225XL0004X', name: 'Low Vision Occupational Therapist' },
    { value: '225XM0800X', name: 'Mental Health Occupational Therapist' },
    { value: '225XN1300X', name: 'Neurorehabilitation Occupational Therapist' },
    { value: '225XP0019X', name: 'Physical Rehabilitation Occupational Therapist' },
    { value: '225XP0200X', name: 'Pediatric Occupational Therapist' },
    { value: '225XR0403X', name: 'Driving and Community Mobility Occupational Therapist' },
    { value: '226000000X', name: 'Recreational Therapist Assistant' },
    { value: '226300000X', name: 'Kinesiotherapist' },
    { value: '227800000X', name: 'Certified Respiratory Therapist' },
    { value: '2278C0205X', name: 'Critical Care Certified Respiratory Therapist' },
    { value: '2278E0002X', name: 'Emergency Care Certified Respiratory Therapist' },
    { value: '2278E1000X', name: 'Educational Certified Respiratory Therapist' },
    { value: '2278G0305X', name: 'Geriatric Care Certified Respiratory Therapist' },
    { value: '2278G1100X', name: 'General Care Certified Respiratory Therapist' },
    { value: '2278H0200X', name: 'Home Health Certified Respiratory Therapist' },
    { value: '2278P1004X', name: 'Pulmonary Diagnostics Certified Respiratory Therapist' },
    { value: '2278P1005X', name: 'Pulmonary Rehabilitation Certified Respiratory Therapist' },
    { value: '2278P1006X', name: 'Pulmonary Function Technologist Certified Respiratory Therapist' },
    { value: '2278P3800X', name: 'Palliative/Hospice Certified Respiratory Therapist' },
    { value: '2278P3900X', name: 'Neonatal/Pediatric Certified Respiratory Therapist' },
    { value: '2278P4000X', name: 'Patient Transport Certified Respiratory Therapist' },
    { value: '2278S1500X', name: 'SNF/Subacute Care Certified Respiratory Therapist' },
    { value: '227900000X', name: 'Registered Respiratory Therapist' },
    { value: '2279C0205X', name: 'Critical Care Registered Respiratory Therapist' },
    { value: '2279E0002X', name: 'Emergency Care Registered Respiratory Therapist' },
    { value: '2279E1000X', name: 'Educational Registered Respiratory Therapist' },
    { value: '2279G0305X', name: 'Geriatric Care Registered Respiratory Therapist' },
    { value: '2279G1100X', name: 'General Care Registered Respiratory Therapist' },
    { value: '2279H0200X', name: 'Home Health Registered Respiratory Therapist' },
    { value: '2279P1004X', name: 'Pulmonary Diagnostics Registered Respiratory Therapist' },
    { value: '2279P1005X', name: 'Pulmonary Rehabilitation Registered Respiratory Therapist' },
    { value: '2279P1006X', name: 'Pulmonary Function Technologist Registered Respiratory Therapist' },
    { value: '2279P3800X', name: 'Palliative/Hospice Registered Respiratory Therapist' },
    { value: '2279P3900X', name: 'Neonatal/Pediatric Registered Respiratory Therapist' },
    { value: '2279P4000X', name: 'Patient Transport Registered Respiratory Therapist' },
    { value: '2279S1500X', name: 'SNF/Subacute Care Registered Respiratory Therapist' },
    { value: '229N00000X', name: 'Anaplastologist' },
    { value: '231H00000X', name: 'Audiologist' },
    { value: '231HA2400X', name: 'Assistive Technology Practitioner Audiologist' },
    { value: '231HA2500X', name: 'Assistive Technology Supplier Audiologist' },
    { value: '235500000X', name: 'Speech/Language/Hearing Specialist/Technologist' },
    { value: '2355A2700X', name: 'Audiology Assistant' },
    { value: '2355S0801X', name: 'Speech-Language Assistant' },
    { value: '235Z00000X', name: 'Speech-Language Pathologist' },
    { value: '237600000X', name: 'Audiologist-Hearing Aid Fitter' },
    { value: '237700000X', name: 'Hearing Instrument Specialist' },
    { value: '242T00000X', name: 'Perfusionist' },
    { value: '243U00000X', name: 'Radiology Practitioner Assistant' },
    { value: '246Q00000X', name: 'Pathology Specialist/Technologist' },
    { value: '246QB0000X', name: 'Blood Banking Specialist/Technologist' },
    { value: '246QC1000X', name: 'Chemistry Pathology Specialist/Technologist' },
    { value: '246QC2700X', name: 'Cytotechnology Specialist/Technologist' },
    { value: '246QH0000X', name: 'Hematology Specialist/Technologist' },
    { value: '246QH0401X', name: 'Hemapheresis Practitioner' },
    { value: '246QH0600X', name: 'Histology Specialist/Technologist' },
    { value: '246QI0000X', name: 'Immunology Pathology Specialist/Technologist' },
    { value: '246QL0900X', name: 'Laboratory Management Specialist/Technologist' },
    { value: '246QL0901X', name: 'Diplomate Laboratory Management Specialist/Technologist' },
    { value: '246QM0706X', name: 'Medical Technologist' },
    { value: '246QM0900X', name: 'Microbiology Specialist/Technologist' },
    { value: '246R00000X', name: 'Pathology Technician' },
    { value: '246RH0600X', name: 'Histology Technician' },
    { value: '246RM2200X', name: 'Medical Laboratory Technician' },
    { value: '246RP1900X', name: 'Phlebotomy Technician' },
    { value: '246W00000X', name: 'Cardiology Technician' },
    { value: '246X00000X', name: 'Cardiovascular Specialist/Technologist' },
    { value: '246XC2901X', name: 'Cardiovascular Invasive Specialist/Technologist' },
    { value: '246XC2903X', name: 'Vascular Specialist/Technologist' },
    { value: '246XS1301X', name: 'Sonography Specialist/Technologist' },
    { value: '246Y00000X', name: 'Health Information Specialist/Technologist' },
    { value: '246YC3301X', name: 'Hospital Based Coding Specialist' },
    { value: '246YC3302X', name: 'Physician Office Based Coding Specialist' },
    { value: '246YR1600X', name: 'Registered Record Administrator' },
    { value: '246Z00000X', name: 'Other Specialist/Technologist' },
    { value: '246ZA2600X', name: 'Medical Art Specialist/Technologist' },
    { value: '246ZB0301X', name: 'Biomedical Engineer' },
    { value: '246ZB0302X', name: 'Biomedical Photographer' },
    { value: '246ZB0500X', name: 'Biochemist' },
    { value: '246ZB0600X', name: 'Biostatiscian' },
    { value: '246ZC0007X', name: 'Surgical Assistant' },
    { value: '246ZE0500X', name: 'EEG Specialist/Technologist' },
    { value: '246ZE0600X', name: 'Electroneurodiagnostic Specialist/Technologist' },
    { value: '246ZG0701X', name: 'Graphics Methods Specialist/Technologist' },
    { value: '246ZG1000X', name: 'Medical Geneticist (PhD) Specialist/Technologist' },
    { value: '246ZI1000X', name: 'Medical Illustrator' },
    { value: '246ZN0300X', name: 'Nephrology Specialist/Technologist' },
    { value: '246ZS0410X', name: 'Surgical Technologist' },
    { value: '246ZX2200X', name: 'Orthopedic Assistant' },
    { value: '247000000X', name: 'Health Information Technician' },
    { value: '2470A2800X', name: 'Assistant Health Information Record Technician' },
    { value: '247100000X', name: 'Radiologic Technologist' },
    { value: '2471B0102X', name: 'Bone Densitometry Radiologic Technologist' },
    { value: '2471C1101X', name: 'Cardiovascular-Interventional Technology Radiologic Technologist' },
    { value: '2471C1106X', name: 'Cardiac-Interventional Technology Radiologic Technologist' },
    { value: '2471C3401X', name: 'Computed Tomography Radiologic Technologist' },
    { value: '2471C3402X', name: 'Radiography Radiologic Technologist' },
    { value: '2471M1202X', name: 'Magnetic Resonance Imaging Radiologic Technologist' },
    { value: '2471M2300X', name: 'Mammography Radiologic Technologist' },
    { value: '2471N0900X', name: 'Nuclear Medicine Technology Radiologic Technologist' },
    { value: '2471Q0001X', name: 'Quality Management Radiologic Technologist' },
    { value: '2471R0002X', name: 'Radiation Therapy Radiologic Technologist' },
    { value: '2471S1302X', name: 'Sonography Radiologic Technologist' },
    { value: '2471V0105X', name: 'Vascular Sonography Radiologic Technologist' },
    { value: '2471V0106X', name: 'Vascular-Interventional Technology Radiologic Technologist' },
    { value: '247200000X', name: 'Other Technician' },
    { value: '2472B0301X', name: 'Biomedical Engineering Technician' },
    { value: '2472D0500X', name: 'Darkroom Technician' },
    { value: '2472E0500X', name: 'EEG Technician' },
    { value: '2472R0900X', name: 'Renal Dialysis Technician' },
    { value: '2472V0600X', name: 'Veterinary Technician' },
    { value: '247ZC0005X', name: 'Clinical Laboratory Director (Non-physician)' },
    { value: '342000000X', name: 'Transportation Network Company' },
    { value: '363A00000X', name: 'Physician Assistant' },
    { value: '363AM0700X', name: 'Medical Physician Assistant' },
    { value: '363AS0400X', name: 'Surgical Physician Assistant' },
    { value: '363L00000X', name: 'Nurse Practitioner' },
    { value: '363LA2100X', name: 'Acute Care Nurse Practitioner' },
    { value: '363LA2200X', name: 'Adult Health Nurse Practitioner' },
    { value: '363LC0200X', name: 'Critical Care Medicine Nurse Practitioner' },
    { value: '363LC1500X', name: 'Community Health Nurse Practitioner' },
    { value: '363LF0000X', name: 'Family Nurse Practitioner' },
    { value: '363LG0600X', name: 'Gerontology Nurse Practitioner' },
    { value: '363LN0000X', name: 'Neonatal Nurse Practitioner' },
    { value: '363LN0005X', name: 'Critical Care Neonatal Nurse Practitioner' },
    { value: '363LP0200X', name: 'Pediatric Nurse Practitioner' },
    { value: '363LP0222X', name: 'Critical Care Pediatric Nurse Practitioner' },
    { value: '363LP0808X', name: 'Psychiatric/Mental Health Nurse Practitioner' },
    { value: '363LP1700X', name: 'Perinatal Nurse Practitioner' },
    { value: '363LP2300X', name: 'Primary Care Nurse Practitioner' },
    { value: '363LS0200X', name: 'School Nurse Practitioner' },
    { value: '363LW0102X', name: 'Womens Health Nurse Practitioner' },
    { value: '363LX0001X', name: 'Obstetrics & Gynecology Nurse Practitioner' },
    { value: '363LX0106X', name: 'Occupational Health Nurse Practitioner' },
    { value: '364S00000X', name: 'Clinical Nurse Specialist' },
    { value: '364SA2100X', name: 'Acute Care Clinical Nurse Specialist' },
    { value: '364SA2200X', name: 'Adult Health Clinical Nurse Specialist' },
    { value: '364SC0200X', name: 'Critical Care Medicine Clinical Nurse Specialist' },
    { value: '364SC1501X', name: 'Community Health/Public Health Clinical Nurse Specialist' },
    { value: '364SC2300X', name: 'Chronic Care Clinical Nurse Specialist' },
    { value: '364SE0003X', name: 'Emergency Clinical Nurse Specialist' },
    { value: '364SE1400X', name: 'Ethics Clinical Nurse Specialist' },
    { value: '364SF0001X', name: 'Family Health Clinical Nurse Specialist' },
    { value: '364SG0600X', name: 'Gerontology Clinical Nurse Specialist' },
    { value: '364SH0200X', name: 'Home Health Clinical Nurse Specialist' },
    { value: '364SH1100X', name: 'Holistic Clinical Nurse Specialist' },
    { value: '364SI0800X', name: 'Informatics Clinical Nurse Specialist' },
    { value: '364SL0600X', name: 'Long-Term Care Clinical Nurse Specialist' },
    { value: '364SM0705X', name: 'Medical-Surgical Clinical Nurse Specialist' },
    { value: '364SN0000X', name: 'Neonatal Clinical Nurse Specialist' },
    { value: '364SN0800X', name: 'Neuroscience Clinical Nurse Specialist' },
    { value: '364SP0200X', name: 'Pediatric Clinical Nurse Specialist' },
    { value: '364SP0807X', name: 'Child & Adolescent Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP0808X', name: 'Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP0809X', name: 'Adult Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP0810X', name: 'Child & Family Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP0811X', name: 'Chronically Ill Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP0812X', name: 'Community Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP0813X', name: 'Geropsychiatric Psychiatric/Mental Health Clinical Nurse Specialist' },
    { value: '364SP1700X', name: 'Perinatal Clinical Nurse Specialist' },
    { value: '364SP2800X', name: 'Perioperative Clinical Nurse Specialist' },
    { value: '364SR0400X', name: 'Rehabilitation Clinical Nurse Specialist' },
    { value: '364SS0200X', name: 'School Clinical Nurse Specialist' },
    { value: '364ST0500X', name: 'Transplantation Clinical Nurse Specialist' },
    { value: '364SW0102X', name: 'Womens Health Clinical Nurse Specialist' },
    { value: '364SX0106X', name: 'Occupational Health Clinical Nurse Specialist' },
    { value: '364SX0200X', name: 'Oncology Clinical Nurse Specialist' },
    { value: '364SX0204X', name: 'Pediatric Oncology Clinical Nurse Specialist' },
    { value: '367500000X', name: 'Certified Registered Nurse Anesthetist' },
    { value: '367A00000X', name: 'Advanced Practice Midwife' },
    { value: '367H00000X', name: 'Anesthesiologist Assistant' },
    { value: '372500000X', name: 'Chore Provider' },
    { value: '372600000X', name: 'Adult Companion' },
    { value: '373H00000X', name: 'Day Training/Habilitation Specialist' },
    { value: '374700000X', name: 'Technician' },
    { value: '3747A0650X', name: 'Attendant Care Provider' },
    { value: '3747P1801X', name: 'Personal Care Attendant' },
    { value: '374J00000X', name: 'Doula' },
    { value: '374K00000X', name: 'Religious Nonmedical Practitioner' },
    { value: '374T00000X', name: 'Religious Nonmedical Nursing Personnel' },
    { value: '374U00000X', name: 'Home Health Aide' },
    { value: '376G00000X', name: 'Nursing Home Administrator' },
    { value: '376J00000X', name: 'Homemaker' },
    { value: '376K00000X', name: 'Nurses Aide' },
    { value: '405300000X', name: 'Prevention Professional' }
  ].freeze
    
  SPECIALTIES = (NON_INDIVIDUAL_SPECIALTIES + INDIVIDUAL_AND_GROUP_SPECIALTIES).freeze 
    
  PHARMACY_SPECIALTIES = [
    { value: '333600000X', name: 'Pharmacy' },
    { value: '3336C0002X', name: 'Clinic Pharmacy' },
    { value: '3336C0003X', name: 'Community/Retail Pharmacy' },
    { value: '3336C0004X', name: 'Compounding Pharmacy' },
    { value: '3336H0001X', name: 'Home Infusion Therapy Pharmacy' },
    { value: '3336I0012X', name: 'Institutional Pharmacy' },
    { value: '3336L0003X', name: 'Long Term Care Pharmacy' },
    { value: '3336M0002X', name: 'Mail Order Pharmacy' },
    { value: '3336M0003X', name: 'Managed Care Organization Pharmacy' },
    { value: '3336N0007X', name: 'Nuclear Pharmacy' },
    { value: '3336S0011X', name: 'Specialty Pharmacy' }
  ].freeze 

  NUCC_CODES = [
    { value: '101Y00000X', name: 'Counselor' },
    { value: '102L00000X', name: 'Psychoanalyst' },
    { value: '102X00000X', name: 'Poetry Therapist' },
    { value: '103G00000X', name: 'Clinical Neuropsychologist' },
    { value: '103K00000X', name: 'Behavior Analyst' },
    { value: '103T00000X', name: 'Psychologist' },
    { value: '104100000X', name: 'Social Worker' },
    { value: '106E00000X', name: 'Assistant Behavior Analyst' },
    { value: '106H00000X', name: 'Marriage & Family Therapist' },
    { value: '106S00000X', name: 'Behavior Technician' },
    { value: '111N00000X', name: 'Chiropractor' },
    { value: '122300000X', name: 'Dentist' },
    { value: '122400000X', name: 'Denturist' },
    { value: '124Q00000X', name: 'Dental Hygienist' },
    { value: '125J00000X', name: 'Dental Therapist' },
    { value: '125K00000X', name: 'Advanced Practice Dental Therapist' },
    { value: '125Q00000X', name: 'Oral Medicinist' },
    { value: '126800000X', name: 'Dental Assistant' },
    { value: '126900000X', name: 'Dental Laboratory Technician' },
    { value: '132700000X', name: 'Dietary Manager' },
    { value: '133N00000X', name: 'Nutritionist' },
    { value: '133V00000X', name: 'Dietitian, Registered' },
    { value: '136A00000X', name: 'Dietetic Technician, Registered' },
    { value: '146D00000X', name: 'Personal Emergency Response Attendant' },
    { value: '146L00000X', name: 'Emergency Medical Technician, Paramedic' },
    { value: '146M00000X', name: 'Emergency Medical Technician, Intermediate' },
    { value: '146N00000X', name: 'Emergency Medical Technician, Basic' },
    { value: '152W00000X', name: 'Optometrist' },
    { value: '156F00000X', name: 'Technician/Technologist' },
    { value: '163W00000X', name: 'Registered Nurse' },
    { value: '164W00000X', name: 'Licensed Practical Nurse' },
    { value: '164X00000X', name: 'Licensed Vocational Nurse' },
    { value: '167G00000X', name: 'Licensed Psychiatric Technician' },
    { value: '170100000X', name: 'Medical Genetics, Ph.D. Medical Genetics' },
    { value: '170300000X', name: 'Genetic Counselor, MS' },
    { value: '171000000X', name: 'Military Health Care Provider' },
    { value: '171100000X', name: 'Acupuncturist' },
    { value: '171M00000X', name: 'Case Manager/Care Coordinator' },
    { value: '171R00000X', name: 'Interpreter' },
    { value: '171W00000X', name: 'Contractor' },
    { value: '172A00000X', name: 'Driver' },
    { value: '172M00000X', name: 'Mechanotherapist' },
    { value: '172P00000X', name: 'Naprapath' },
    { value: '172V00000X', name: 'Community Health Worker' },
    { value: '173000000X', name: 'Legal Medicine' },
    { value: '173C00000X', name: 'Reflexologist' },
    { value: '173F00000X', name: 'Sleep Specialist, PhD' },
    { value: '174200000X', name: 'Meals' },
    { value: '174400000X', name: 'Specialist' },
    { value: '174H00000X', name: 'Health Educator' },
    { value: '174M00000X', name: 'Veterinarian' },
    { value: '174N00000X', name: 'Lactation Consultant, Non-RN' },
    { value: '174V00000X', name: 'Clinical Ethicist' },
    { value: '175F00000X', name: 'Naturopath' },
    { value: '175L00000X', name: 'Homeopath' },
    { value: '175M00000X', name: 'Midwife, Lay' },
    { value: '175T00000X', name: 'Peer Specialist' },
    { value: '176B00000X', name: 'Midwife' },
    { value: '176P00000X', name: 'Funeral Director' },
    { value: '177F00000X', name: 'Lodging' },
    { value: '183500000X', name: 'Pharmacist' },
    { value: '183700000X', name: 'Pharmacy Technician' },
    { value: '193200000X', name: 'Multi-Specialty' },
    { value: '193400000X', name: 'Single Specialty' },
    { value: '202C00000X', name: 'Independent Medical Examiner' },
    { value: '202K00000X', name: 'Phlebology' },
    { value: '204C00000X', name: 'Neuromusculoskeletal Medicine, Sports Medicine' },
    { value: '204D00000X', name: 'Neuromusculoskeletal Medicine & OMM' },
    { value: '204E00000X', name: 'Oral & Maxillofacial Surgery' },
    { value: '204F00000X', name: 'Transplant Surgery' },
    { value: '204R00000X', name: 'Electrodiagnostic Medicine' },
    { value: '207K00000X', name: 'Allergy & Immunology' },
    { value: '207L00000X', name: 'Anesthesiology' },
    { value: '207N00000X', name: 'Dermatology' },
    { value: '207P00000X', name: 'Emergency Medicine' },
    { value: '207Q00000X', name: 'Family Medicine' },
    { value: '207R00000X', name: 'Internal Medicine' },
    { value: '207T00000X', name: 'Neurological Surgery' },
    { value: '207U00000X', name: 'Nuclear Medicine' },
    { value: '207V00000X', name: 'Obstetrics & Gynecology' },
    { value: '207W00000X', name: 'Ophthalmology' },
    { value: '207X00000X', name: 'Orthopaedic Surgery' },
    { value: '207Y00000X', name: 'Otolaryngology' },
    { value: '208000000X', name: 'Pediatrics' },
    { value: '208100000X', name: 'Physical Medicine & Rehabilitation' },
    { value: '208200000X', name: 'Plastic Surgery' },
    { value: '208600000X', name: 'Surgery' },
    { value: '208800000X', name: 'Urology' },
    { value: '208C00000X', name: 'Colon & Rectal Surgery' },
    { value: '208D00000X', name: 'General Practice' },
    { value: '208G00000X', name: 'Thoracic Surgery (Cardiothoracic Vascular Surgery)' },
    { value: '208M00000X', name: 'Hospitalist' },
    { value: '208U00000X', name: 'Clinical Pharmacology' },
    { value: '209800000X', name: 'Legal Medicine' },
    { value: '211D00000X', name: 'Assistant, Podiatric' },
    { value: '213E00000X', name: 'Podiatrist' },
    { value: '221700000X', name: 'Art Therapist' },
    { value: '222Q00000X', name: 'Developmental Therapist' },
    { value: '222Z00000X', name: 'Orthotist' },
    { value: '224900000X', name: 'Mastectomy Fitter' },
    { value: '224L00000X', name: 'Pedorthist' },
    { value: '224P00000X', name: 'Prosthetist' },
    { value: '224Y00000X', name: 'Clinical Exercise Physiologist' },
    { value: '224Z00000X', name: 'Occupational Therapy Assistant' },
    { value: '225000000X', name: 'Orthotic Fitter' },
    { value: '225100000X', name: 'Physical Therapist' },
    { value: '225200000X', name: 'Physical Therapy Assistant' },
    { value: '225400000X', name: 'Rehabilitation Practitioner' },
    { value: '225500000X', name: 'Specialist/Technologist' },
    { value: '225600000X', name: 'Dance Therapist' },
    { value: '225700000X', name: 'Massage Therapist' },
    { value: '225800000X', name: 'Recreation Therapist' },
    { value: '225A00000X', name: 'Music Therapist' },
    { value: '225B00000X', name: 'Pulmonary Function Technologist' },
    { value: '225C00000X', name: 'Rehabilitation Counselor' },
    { value: '225X00000X', name: 'Occupational Therapist' },
    { value: '226000000X', name: 'Recreational Therapist Assistant' },
    { value: '226300000X', name: 'Kinesiotherapist' },
    { value: '227800000X', name: 'Respiratory Therapist, Certified' },
    { value: '227900000X', name: 'Respiratory Therapist, Registered' },
    { value: '229N00000X', name: 'Anaplastologist' },
    { value: '231H00000X', name: 'Audiologist' },
    { value: '235500000X', name: 'Specialist/Technologist' },
    { value: '235Z00000X', name: 'Speech-Language Pathologist' },
    { value: '237600000X', name: 'Audiologist-Hearing Aid Fitter' },
    { value: '237700000X', name: 'Hearing Instrument Specialist' },
    { value: '242T00000X', name: 'Perfusionist' },
    { value: '243U00000X', name: 'Radiology Practitioner Assistant' },
    { value: '246Q00000X', name: 'Specialist/Technologist, Pathology' },
    { value: '246R00000X', name: 'Technician, Pathology' },
    { value: '246W00000X', name: 'Technician, Cardiology' },
    { value: '246X00000X', name: 'Specialist/Technologist Cardiovascular' },
    { value: '246Y00000X', name: 'Specialist/Technologist, Health Information' },
    { value: '246Z00000X', name: 'Specialist/Technologist, Other' },
    { value: '247000000X', name: 'Technician, Health Information' },
    { value: '247100000X', name: 'Radiologic Technologist' },
    { value: '247200000X', name: 'Technician, Other' },
    { value: '251300000X', name: 'Local Education Agency (LEA)' },
    { value: '251B00000X', name: 'Case Management' },
    { value: '251C00000X', name: 'Day Training, Developmentally Disabled Services' },
    { value: '251E00000X', name: 'Home Health' },
    { value: '251F00000X', name: 'Home Infusion' },
    { value: '251G00000X', name: 'Hospice Care, Community Based' },
    { value: '251J00000X', name: 'Nursing Care' },
    { value: '251K00000X', name: 'Public Health or Welfare' },
    { value: '251S00000X', name: 'Community/Behavioral Health' },
    { value: '251T00000X', name: 'Program of All-Inclusive Care for the Elderly (PACE) Provider Organization' },
    { value: '251V00000X', name: 'Voluntary or Charitable' },
    { value: '251X00000X', name: 'Supports Brokerage' },
    { value: '252Y00000X', name: 'Early Intervention Provider Agency' },
    { value: '253J00000X', name: 'Foster Care Agency' },
    { value: '253Z00000X', name: 'In Home Supportive Care' },
    { value: '261Q00000X', name: 'Clinic/Center' },
    { value: '273100000X', name: 'Epilepsy Unit' },
    { value: '273R00000X', name: 'Psychiatric Unit' },
    { value: '273Y00000X', name: 'Rehabilitation Unit' },
    { value: '275N00000X', name: 'Medicare Defined Swing Bed Unit' },
    { value: '276400000X', name: 'Rehabilitation, Substance Use Disorder Unit' },
    { value: '281P00000X', name: 'Chronic Disease Hospital' },
    { value: '282E00000X', name: 'Long Term Care Hospital' },
    { value: '282J00000X', name: 'Religious Nonmedical Health Care Institution' },
    { value: '282N00000X', name: 'General Acute Care Hospital' },
    { value: '283Q00000X', name: 'Psychiatric Hospital' },
    { value: '283X00000X', name: 'Rehabilitation Hospital' },
    { value: '284300000X', name: 'Special Hospital' },
    { value: '286500000X', name: 'Military Hospital' },
    { value: '287300000X', name: 'Christian Science Sanitorium' },
    { value: '291900000X', name: 'Military Clinical Medical Laboratory' },
    { value: '291U00000X', name: 'Clinical Medical Laboratory' },
    { value: '292200000X', name: 'Dental Laboratory' },
    { value: '293D00000X', name: 'Physiological Laboratory' },
    { value: '302F00000X', name: 'Exclusive Provider Organization' },
    { value: '302R00000X', name: 'Health Maintenance Organization' },
    { value: '305R00000X', name: 'Preferred Provider Organization' },
    { value: '305S00000X', name: 'Point of Service' },
    { value: '310400000X', name: 'Assisted Living Facility' },
    { value: '310500000X', name: 'Intermediate Care Facility, Mental Illness' },
    { value: '311500000X', name: 'Alzheimer Center (Dementia Center)' },
    { value: '311Z00000X', name: 'Custodial Care Facility' },
    { value: '313M00000X', name: 'Nursing Facility/Intermediate Care Facility' },
    { value: '314000000X', name: 'Skilled Nursing Facility' },
    { value: '315D00000X', name: 'Hospice, Inpatient' },
    { value: '315P00000X', name: 'Intermediate Care Facility, Mentally Retarded' },
    { value: '317400000X', name: 'Christian Science Facility' },
    { value: '320600000X', name: 'Residential Treatment Facility, Mental Retardation and/or Developmental Disabilities' },
    { value: '320700000X', name: 'Residential Treatment Facility, Physical Disabilities' },
    { value: '320800000X', name: 'Community Based Residential Treatment Facility, Mental Illness' },
    { value: '320900000X', name: 'Intellectual and/or Developmental Disabilities Community Based Residential Treatment Facility' },
    { value: '322D00000X', name: 'Residential Treatment Facility, Emotionally Disturbed Children' },
    { value: '323P00000X', name: 'Psychiatric Residential Treatment Facility' },
    { value: '324500000X', name: 'Substance Abuse Rehabilitation Facility' },
    { value: '331L00000X', name: 'Blood Bank' },
    { value: '332000000X', name: 'Military/U.S. Coast Guard Pharmacy' },
    { value: '332100000X', name: 'Department of Veterans Affairs (VA) Pharmacy' },
    { value: '332800000X', name: 'Indian Health Service/Tribal/Urban Indian Health (I/T/U) Pharmacy' },
    { value: '332900000X', name: 'Non-Pharmacy Dispensing Site' },
    { value: '332B00000X', name: 'Durable Medical Equipment & Medical Supplies' },
    { value: '332G00000X', name: 'Eye Bank' },
    { value: '332H00000X', name: 'Eyewear Supplier' },
    { value: '332S00000X', name: 'Hearing Aid Equipment' },
    { value: '332U00000X', name: 'Home Delivered Meals' },
    { value: '333300000X', name: 'Emergency Response System Companies' },
    { value: '333600000X', name: 'Pharmacy' },
    { value: '335E00000X', name: 'Prosthetic/Orthotic Supplier' },
    { value: '335G00000X', name: 'Medical Foods Supplier' },
    { value: '335U00000X', name: 'Organ Procurement Organization' },
    { value: '335V00000X', name: 'Portable X-ray and/or Other Portable Diagnostic Imaging Supplier' },
    { value: '341600000X', name: 'Ambulance' },
    { value: '341800000X', name: 'Military/U.S. Coast Guard Transport' },
    { value: '343800000X', name: 'Secured Medical Transport (VAN)' },
    { value: '343900000X', name: 'Non-emergency Medical Transport (VAN)' },
    { value: '344600000X', name: 'Taxi' },
    { value: '344800000X', name: 'Air Carrier' },
    { value: '347B00000X', name: 'Bus' },
    { value: '347C00000X', name: 'Private Vehicle' },
    { value: '347D00000X', name: 'Train' },
    { value: '347E00000X', name: 'Transportation Broker' },
    { value: '363A00000X', name: 'Physician Assistant' },
    { value: '363L00000X', name: 'Nurse Practitioner' },
    { value: '364S00000X', name: 'Clinical Nurse Specialist' },
    { value: '367500000X', name: 'Nurse Anesthetist, Certified Registered' },
    { value: '367A00000X', name: 'Advanced Practice Midwife' },
    { value: '367H00000X', name: 'Anesthesiologist Assistant' },
    { value: '372500000X', name: 'Chore Provider' },
    { value: '372600000X', name: 'Adult Companion' },
    { value: '373H00000X', name: 'Day Training/Habilitation Specialist' },
    { value: '374700000X', name: 'Technician' },
    { value: '374J00000X', name: 'Doula' },
    { value: '374K00000X', name: 'Religious Nonmedical Practitioner' },
    { value: '374T00000X', name: 'Religious Nonmedical Nursing Personnel' },
    { value: '374U00000X', name: 'Home Health Aide' },
    { value: '376G00000X', name: 'Nursing Home Administrator' },
    { value: '376J00000X', name: 'Homemaker' },
    { value: '376K00000X', name: "Nurse's Aide" },
    { value: '385H00000X', name: 'Respite Care' },
    { value: '390200000X', name: 'Student in an Organized Health Care Education/Training Program' },
    { value: '405300000X', name: 'Prevention Professional' }
  ].freeze

end
