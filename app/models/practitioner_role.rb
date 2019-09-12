################################################################################
#
# PractitionerRole Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PractitionerRole < Resource

	include ActiveModel::Model

	attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier, 
									:active, :period, :practitioner, :organization, :code, 
									:specialties, :locations, :healthcare_services, :telecoms, 
									:available_times, :not_availables, :availability_exceptions,
									:endpoints

	#-----------------------------------------------------------------------------

	def initialize(practitioner_role)
		@id 											= practitioner_role.id
		@period 									= practitioner_role.period
		@practitioner 						= practitioner_role.practitioner
		@organization							= practitioner_role.organization
		@code 										= practitioner_role.code
		@specialties 							= practitioner_role.specialty
		@locations								= practitioner_role.location
		@healthcare_services			= practitioner_role.healthcareService
		@telecoms 								= practitioner_role.telecom
		@available_times 					= practitioner_role.availableTime
		@not_availables 					= practitioner_role.notAvailable
		@availability_exceptions 	= practitioner_role.availabilityExceptions
		@endpoints								= practitioner_role.endpoint
	end
	
end