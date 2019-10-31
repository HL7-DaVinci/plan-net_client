# frozen_string_literal: true

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
    when 'notice'
      css_class = 'alert-info'
    when 'success'
      css_class = 'alert-success'
    when 'error'
      css_class = 'alert-danger'
    when 'alert'
      css_class = 'alert-danger'
    end

    css_class
  end

  #-----------------------------------------------------------------------------

  def display_human_name(name)
    result = [name.prefix.join(', '), name.given.join(' '), name.family].join(' ')
    result += ', ' + name.suffix.join(', ') if name.suffix.present?
    sanitize(result)
  end

  #-----------------------------------------------------------------------------

  def display_telecom(telecom)
    sanitize(telecom.system + ': ' + number_to_phone(telecom.value, area_code: true))
  end

  #-----------------------------------------------------------------------------

  def display_identifier(identifier)
    sanitize([identifier.type.text, identifier.value, identifier.assigner.display].join(', '))
  end

  #-----------------------------------------------------------------------------

  # Concatenates a list of display elements.

  def display_list(list)
    sanitize(list.empty? ? 'None' : list.map(&:display).join(', '))
  end

  #-----------------------------------------------------------------------------

  # Concatenates a list of code elements.

  def display_code_list(list)
    sanitize(list.empty? ? 'None' : list.map(&:code).join(', '))
  end

  #-----------------------------------------------------------------------------

  # Concatenates a list of coding display elements.

  def display_coding_list(list)
    if list.empty?
      result = 'None'
    else
      result = []
      list.map(&:coding).each do |coding|
        result << coding.map(&:display)
      end

      result = result.join(', ')
    end

    sanitize(result)
  end

  #-----------------------------------------------------------------------------

  def google_maps(address)
    'https://www.google.com/maps/search/' + html_escape(address.text)
  end

  #-----------------------------------------------------------------------------

  def display_postal_code(postal_code)
    sanitize(postal_code.match(/^\d{9}$/) ?
        postal_code.strip.sub(/([A-Z0-9]+)([A-Z0-9]{4})/, '\1-\2') : postal_code)
  end

  #-----------------------------------------------------------------------------

  def display_reference(reference)
    if reference.present?
      components = reference.reference.split('/')
      sanitize(link_to(reference.display,
                       [components.first.underscore.pluralize, '/', components.last].join))
    end
  end

  #-----------------------------------------------------------------------------

  def display_reference_list(list)
    sanitize(list.map { |element| display_reference(element) }.join(', '))
  end

  #-----------------------------------------------------------------------------

  def display_extension_list(list)
    sanitize(list.map { |extension| display_reference(extension.valueReference) }.join(', '))
  end
end
