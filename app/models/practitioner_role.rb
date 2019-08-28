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
									:active, :period, :code, :specialty, :telecom, :availableTime, 
									:notAvailable, :availabilityExceptions

	#-----------------------------------------------------------------------------

	def initialize(practitioner_role)
		@period 									= practitioner_role.period
		@code 										= practitioner_role.code
		@specialty 								= practitioner_role.specialty
		@telecom 									= practitioner_role.telecom
		@available_time 					= practitioner_role.availableTime
		@not_available 						= practitioner_role.notAvailable
		@availability_exceptions 	= practitioner_role.availabilityExceptions
	end
	
end