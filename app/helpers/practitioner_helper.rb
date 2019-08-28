################################################################################
#
# Practitioner Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module PractitionerHelper

	def display_qualification(qualification)
		return qualification.identifier
	end

	#-----------------------------------------------------------------------------

	def display_identifier(identifier)
		return [ identifier.type.text, identifier.value, identifier.assigner.display ].join(', ')
	end

	#-----------------------------------------------------------------------------

	def display_code(code)
		return code.coding.display
	end

	#-----------------------------------------------------------------------------

	def display_period(period)
		return period.present? ? period.start + ' to ' + period.end : "Not available"
	end

	#-----------------------------------------------------------------------------

	def display_issuer(issuer)
		return issuer.display
	end

end
