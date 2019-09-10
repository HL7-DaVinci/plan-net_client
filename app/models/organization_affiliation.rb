################################################################################
#
# OrganizationAffiliation Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class OrganizationAffiliation < Resource

	include ActiveModel::Model

	attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier, 
									:active, :networks, :identifiers, :organization, 
									:participating_organization, :codes, :specialties, :locations,
									:healthcare_services, :telecoms, :endpoints

	#-----------------------------------------------------------------------------

	def initialize(organization_affiliation)
		@id 													= organization_affiliation.id
		@networks 										= organization_affiliation.extension
		@identifiers 									= organization_affiliation.identifier
		@organization 								= organization_affiliation.organization
		@participating_organization 	= organization_affiliation.participatingOrganization
		@codes												= organization_affiliation.code
		@specialties									= organization_affiliation.specialty
		@locations										= organization_affiliation.location
		@healthcare_services					= organization_affiliation.healthcareService
		@telecoms											= organization_affiliation.telecom
		@endpoints										= organization_affiliation.endpoint
	end
	
end