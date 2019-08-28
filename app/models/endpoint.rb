################################################################################
#
# Endpoint Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Endpoint < Resource

	include ActiveModel::Model

	attr_accessor :id, :meta, :implicit_rules, :language, :text, :identifier, 
									:active, :connection_type, :name, :managing_organization,
									:contacts, :period, :payload_types, :payload_mime_types,
									:headers

	#-----------------------------------------------------------------------------

	def initialize(endpoint)
		@connection_type				= endpoint.connectionType
		@name										= endpoint.name
		@managing_organization	= endpoint.managingOrganization
		@contacts								= endpoint.contact
		@period									= endpoint.period
		@payload_types 					= endpoint.payloadType
		@payload_mime_types			= endpoint.payloadMimeType
		@headers								= endpoint.header
	end
	
end