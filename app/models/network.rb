################################################################################
#
# Network Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Network < Resource

	include ActiveModel::Model

	attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier, 
									:active

	#-----------------------------------------------------------------------------

	def initialize(network)
	end
	
end