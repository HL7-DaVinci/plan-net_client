require "rubygems"
require "net/https"
require "uri"
require "json"
require "pry"
require "fhir_client"

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

def client
    server_url = "https://davinci-plan-net-ri.logicahealth.org/fhir/"
     client = FHIR::Client.new(server_url)
    client.use_r4
    client.additional_headers = { 'Accept-Encoding' => 'identity' }  # 
    client.set_basic_auth("fhiruser","change-password")
    client 
end

def plan_networks (id)
    network_list = []
    results = client.search(
      FHIR::InsurancePlan,
      search: { 
        parameters: {
      #    type: 'http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan',
          _id: "#{id}"
        } 
      }
    )
    results&.resource&.entry[0]&.resource&.network.map do |network|
        network.reference
    end
  end

  # A pharmacy location can be associated with multiple organization affiliation relationships and multiple specialties
  # We will report "mix" as:
  #   - total unique organizations and locations (specialty = nil)
  #   - For each of the pharmacy specialties (compounding, retail, mailorder, etc) - unique organizations and locations
  # Tje building block is a query for pharmacy locations by network and specialty that will return {specialty: <specialty>, organizations: <organizations>, locations: <locations>}
  def pharmacy_locations(networks, specialty, specialtydisplay)
    # retrieve organizationaffiliations that satisfy type=pharmacy and specialty = specialty (if provided)
    # build collection of unique locations

    #retrieve organization affiliations that satisfy type=pharmacy and specialty = specialty
    parameters = {
        network: networks,
        role: "pharmacy"
    } 
    parameters["specialty"] = specialty if specialty 

    organizations = {}
    locations = {}
    bundle = client.search(
        FHIR::OrganizationAffiliation,
        search: { 
          parameters: parameters
        }
      ).resource 
      locations = {}
      organizations = {}
      loop do
        fhir_orgaffs = bundle.entry.select { |entry| entry.resource.instance_of? FHIR::OrganizationAffiliation }.map(&:resource)
        fhir_orgaffs.map  do  |orgaff| 
            organizations[orgaff.participatingOrganization.reference] = true
            orgaff.location.map do |location|
                locations[location.reference] = true
            end
        end
        url = bundle&.next_link&.url
        break if url.present? == false
        bundle = client.parse_reply(FHIR::Bundle, client.default_format,  client.raw_read_url(url))
      end
      { "specialty": specialtydisplay,
        "organization": organizations.size,
        "locations": locations.size}
  end

planid= "InsurancePlan/plannet-insuranceplan-HPID360000"
networks = plan_networks (planid)
pharmacy_mix = []
pharmacy_mix << pharmacy_locations(networks, nil, "All")
PHARMACY_SPECIALTIES.map do |specialty|
  pharmacy_mix << pharmacy_locations(networks, specialty[:value], specialty[:name])
end
#binding.pry 

