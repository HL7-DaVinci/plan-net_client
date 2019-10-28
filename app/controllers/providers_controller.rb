################################################################################
#
# Providers Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class ProvidersController < ApplicationController

	before_action :connect_to_server, only: [ :index ]
  before_action :fetch_payers, only: [:index]

	#-----------------------------------------------------------------------------

	# GET /providers

	def index
    @params = {}
	end
end
