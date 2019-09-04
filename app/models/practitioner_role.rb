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
									:active, :period, :code, :specialties, :telecoms, :available_times, 
									:not_available, :availability_exceptions

	#-----------------------------------------------------------------------------

	def initialize(practitioner_role)
		@period 									= practitioner_role.period
		@code 										= practitioner_role.code
		@specialties 							= practitioner_role.specialty
		@telecoms 								= practitioner_role.telecom
		@available_times 					= practitioner_role.availableTime
		@not_available 						= practitioner_role.notAvailable
		@availability_exceptions 	= practitioner_role.availabilityExceptions
	end
	
end