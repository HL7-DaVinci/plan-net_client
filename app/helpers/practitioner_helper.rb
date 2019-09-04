################################################################################
#
# Practitioner Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module PractitionerHelper

	def display_qualification(qualification)
		return sanitize(qualification.identifier)
	end

	#-----------------------------------------------------------------------------

	def display_code(code)
		return sanitize(code.coding.display)
	end

	#-----------------------------------------------------------------------------

	def display_period(period)
		return period.present? ? sanitize(period.start + ' to ' + period.end) : "Not available"
	end

	#-----------------------------------------------------------------------------

	def display_issuer(issuer)
		return sanitize(issuer.display)
	end

end
