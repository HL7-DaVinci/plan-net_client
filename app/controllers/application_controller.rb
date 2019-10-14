################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base

  # Get the FHIR server url
  def server_url
    params[:server_url] || session[:server_url]
  end

  # Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_server
		if server_url.present?
			@client = FHIR::Client.new(server_url)
			@client.use_r4
      session[:server_url] = server_url
		else
			redirect_to root_path, flash: { error: "Please specify a plan network server" }
		end
	end

  def update_bundle_links
    session[:next_bundle] = @bundle&.next_link&.url
    session[:previous_bundle] = @bundle&.previous_link&.url
    @next_page_disabled = session[:next_bundle].blank? ? 'disabled' : ''
    @previous_page_disabled = session[:previous_bundle].blank? ? 'disabled' : ''
  end

	#-----------------------------------------------------------------------------

	# Performs pagination on the resource list.
	#
	# Params:
  # 	+page+:: which page to get

	def update_page(page)
		case page
		when 'previous'
			@bundle = previous_bundle
		when 'next'
			@bundle = next_bundle
		end
	end

	#-----------------------------------------------------------------------------

	# Retrieves the previous bundle page from the FHIR server.

	def previous_bundle
		url = session[:previous_bundle]

		if url.present?
			@client.parse_reply(FHIR::Bundle, @client.default_format,
									@client.raw_read_url(url))
		end
	end

	# Retrieves the next bundle page from the FHIR server.

  def next_bundle
		url = session[:next_bundle]

		if url.present?
			@client.parse_reply(FHIR::Bundle, @client.default_format,
									        @client.raw_read_url(url))
		end
  end

  # Turns a query string such as "name=abc&id=123" into a hash like
  # { 'name' => 'abc', 'id' => '123' }
  def query_hash_from_string(query_string)
    query_string.split('&').each_with_object({}) do |string, hash|
      key, value = string.split('=')
      hash[key] = value
    end
  end
end
