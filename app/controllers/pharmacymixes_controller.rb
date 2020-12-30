class PharmacymixesController < ApplicationController
  before_action :connect_to_server

   # GET /pharmacymixes
   def index
    fetch_plans

    @params = {}

    @plans = @plans.collect{|p| [p[:name], p[:value]]}

  end
  # GET /pharmacymix/search

  def search
        insurance_plan = query_params = params[:pharmacymix]["insurance_plan"]
        networks = plan_networks(insurance_plan)
        # A pharmacy location can be associated with multiple organization affiliation relationships and multiple specialties
      # We will report "mix" as:
      #   - total unique organizations and locations (specialty = nil)
      #   - For each of the pharmacy specialties (compounding, retail, mailorder, etc) - unique organizations and locations
      # Tje building block is a query for pharmacy locations by network and specialty that will return {specialty: <specialty>, organizations: <organizations>, locations: <locations>}
      @items = []
      @items << pharmacy_locations(networks, nil, "All")
      if @items[0][:locations] > 0
        PHARMACY_SPECIALTIES.map do |specialty|
        @items << pharmacy_locations(networks, specialty[:value], specialty[:name])
        end
      end
      respond_to do |format|
        format.js { }
      end
  end
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
    bundle = @client.search(
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
        bundle = @client.parse_reply(FHIR::Bundle, @client.default_format,  @client.raw_read_url(url))
      end
      { "specialty": specialtydisplay,
        "organizations": organizations.size,
        "locations": locations.size}

      rescue => exception
        binding.pry 

  end


  def plan_networks (id)
    network_list = []
    results = @client.search(
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

end

