# frozen_string_literal: true

################################################################################
#
# Application Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################
require 'httparty'

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
    if !identifier.try(:assigner).nil? && !identifier.assigner.try(:display).nil? && !identifier.try(:type).nil? && !identifier.type.try(:text).nil? && !identifier.try(:value).nil?
      sanitize("#{identifier.assigner.display}: ( #{identifier.type&.text}, #{identifier.value})")
    elsif !identifier.try(:value).nil?
      sanitize("#{identifier.value}")
    end
  #    sanitize([identifier.type.text, identifier.value, identifier.assigner.display].join(', '))
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

      result = result.join(',<br />')
    end

    sanitize(result)
  end

  #-----------------------------------------------------------------------------

  def google_maps(address)
    if address.present?
      if address.text.present?
        'https://www.google.com/maps/search/' + html_escape(address.text)
      elsif address.line.present?
        'https://www.google.com/maps/search/' + html_escape("#{address.line.join(' ')} #{address.city} #{address.state}, #{address.postalCode}")
      end
    end
  end

  #-----------------------------------------------------------------------------

  def display_address(address)
    if address.present?
      result =  link_to(google_maps(address)) do 
                  [address.line.join('<br />'), 
                  [[address.city, address.state].join(', '), 
                          display_postal_code(address.postalCode)].join(' ')
                  ].join('<br />').html_safe
                end
    else
      result = 'None'
    end
    
    sanitize(result)
  end

  #-----------------------------------------------------------------------------

  def display_postal_code(postal_code)
    if postal_code.present?
      sanitize(postal_code.match(/^\d{9}$/) ?
          postal_code.strip.sub(/([A-Z0-9]+)([A-Z0-9]{4})/, '\1-\2') : postal_code)
    end
  end

  #-----------------------------------------------------------------------------

  def controller_type (reference)
  end

  #-----------------------------------------------------------------------------

  def display_reference(reference, use_controller: "default")
    if reference.present?
      components = reference.reference.split('/')
      if use_controller.eql?("default")
        controller = components.first.underscore.pluralize
      else
        controller = use_controller
      end

      sanitize(link_to(reference.display,
                       ["/",controller, '/', components.last].join))
    end
  end

  #-----------------------------------------------------------------------------
  
  # use_controller allows us to display networks using the network 
  # controller/view, rather than the organization controller/view.
  # a network is-a organization, but their display needs may be distinct.

  def display_reference_list(list,use_controller: "default")
    sanitize(list.map { |element| display_reference(element,use_controller:use_controller) }.join(',<br />'))
  end

  #-----------------------------------------------------------------------------

  def display_extension_list(list)
    sanitize(list.map { |extension| display_reference(extension.valueReference) }.join(',<br />'))
  end

  #-----------------------------------------------------------------------------

  def display_location_type(list)
    if list.empty?
      result = 'None'
    else
      result = list.map(&:text).join(',<br />')
    end

    sanitize(result)
  end

  #-----------------------------------------------------------------------------

  def format_zip(zip)
    if zip.length > 5
      "#{zip[0..4]}-#{zip[5..-1]}"
    else
      zip
    end
  end
  
end
