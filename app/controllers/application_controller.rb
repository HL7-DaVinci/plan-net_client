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

  #-----------------------------------------------------------------------------

  # Get the FHIR server url
  def server_url
    params[:server_url] || session[:server_url]
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

  #-----------------------------------------------------------------------------

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
    #  Convert zipcode + radius to  address='zipcode list'
    if params[:zip].present?   # delete zip and radius params and replace with address
      zip = params[:zip]
      params.delete(:zip)
      if params[:radius].present?
        radius = params[:radius].to_i
        params.delete(:radius)
      end

      params[:address] = Zipcode.zipcodes_within(radius, zip).join(',')
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
    { value: '320900000X', name: 'Community Based Residential Treatment Facility, Mental Retardation and/or Developmental Disabilities' },
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
