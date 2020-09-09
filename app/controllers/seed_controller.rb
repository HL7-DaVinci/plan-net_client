################################################################################
#
# Seed Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class SeedController < ApplicationController

	def index
		# This is a bit of a hack, but seeding the zipcodes into the database
		# through the traditional 'rake db:seed' or 'bundle exec rake db:seed' 
		# results in a stack overflow error, apparently through the validation
		# logic.

    system('rails db/seeds.db') if Zipcode.count == 0
  end

end
