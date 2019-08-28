################################################################################
#
# Application Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module ApplicationHelper

	# Determines the CSS class of the flash message for display from the 
	# specified level.

	def flash_class(level)
    case level
	    when "notice"
	    	css_class = "alert-info"
	    when "success" 
	    	css_class = "alert-success"
	    when "error"
	    	css_class = "alert-danger"
	    when "alert"
	    	css_class = "alert-danger"
    end

    return css_class
	end

	#-----------------------------------------------------------------------------

	def display_human_name(name)
		result = name.prefix.join(', ') + ' ' + name.family + ', ' + 
							name.given.join(' ')
		result += ', ' + name.suffix.join(', ') if name.suffix.present?
		return result
	end

	#-----------------------------------------------------------------------------

	def display_telecom(telecom)
		return telecom.system + ": " + number_to_phone(telecom.value, area_code: true)
	end

	#-----------------------------------------------------------------------------

	def display_identifier(identifier)
		return [ identifier.type.text, identifier.value, identifier.assigner.display ].join(', ')
	end

	#-----------------------------------------------------------------------------

	# Concatenates a list of display elements.

	def display_list(list)
		list.empty? ? "None" : list.map(&:display).join(', ')
	end

	#-----------------------------------------------------------------------------

	# Concatenates a list of code elements.

	def display_code_list(list)
		list.empty? ? "None" : list.map(&:code).join(', ')
	end

	#-----------------------------------------------------------------------------

	# Concatenates a list of coding display elements.

	def display_coding_list(list)
		if list.empty?
			result = "None"
		else
			result = []
			list.map(&:coding).each do |coding|
				result << coding.map(&:display)
			end

			result = result.join(', ')
		end

		return result
	end

	#-----------------------------------------------------------------------------

	def display_postal_code(postal_code)
  	postal_code.match(/^\d{9}$/) ?
  			postal_code.strip.sub(/([A-Z0-9]+)([A-Z0-9]{4})/, '\1-\2') : postal_code
	end

end
