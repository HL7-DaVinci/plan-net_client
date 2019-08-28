################################################################################
#
# CareTeam Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class CareTeam < Resource

	include ActiveModel::Model

	attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier, 
									:active

	#-----------------------------------------------------------------------------

	def initialize(care_team)
 	end
	
end