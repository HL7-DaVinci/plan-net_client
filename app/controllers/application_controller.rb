################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base

	#-----------------------------------------------------------------------------
	protected
	#-----------------------------------------------------------------------------

	# Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_server
		if params[:server_url].present?
			@@client = FHIR::Client.new(params[:server_url])
			@@client.use_r4
		elsif !defined?(@@client)
			redirect_to root_path, flash: { error: "Please specify a plan network server" }
		end
	end

	#-----------------------------------------------------------------------------

	# Performs pagination on the resource list, reading 10 resources from
	# the server at a time.
	#
	# Params:
  # 	+page+:: Page number to update
  # 	+bundle+:: Bundle to use to retrieve page

	def update_page(page, bundle)
		link = nil

		case page
		when 'previous'
			bundle = previous_bundle(bundle)
		when 'next'
			bundle = bundle.next_bundle
		end

		return bundle
	end

	#-----------------------------------------------------------------------------

	# Retrieves the previous 10 resources from the current position in the 
	# bundle.  FHIR::Bundle in the fhir-client gem only provides direct support 
	# for the next bundle, not the previous bundle.
	#
	# Params:
  # 	+bundle+:: Bundle to use to retrieve previous page from

	def previous_bundle(bundle)
		link = bundle.previous_link

		if link.present?
			new_bundle = @@client.parse_reply(bundle.class, @@client.default_format, 
									@@client.raw_read_url(link.url))
			bundle = new_bundle unless new_bundle.nil?
		end

		return bundle
	end

end
