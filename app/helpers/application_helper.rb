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

    if !name.try(:text).nil?
      result = name.try(:text)
    else
      
      if !name.try(:prefix).nil?
        result = name.try(:prefix).join(', ')
      end
  
      if !name.try(:given).nil?
        if result.length != 0
          result = result + ' '
        end
        result = result + name.try(:given).join(', ')
      end
      if !name.try(:family).nil?
        if result.length != 0
          result = result + ' '
        end
        result = result + name.try(:family)
      end
  
      if !name.try(:suffix).nil?
        if result.length != 0
          result = result + ' '
        end
        result = result + name.try(:suffix).join(', ')
      end
      
    end

    sanitize(result)
    
  end


  #def display_human_name(name)
  #  result = "None"
  #  puts name.inspect

    #result = [if name.prefix.nil? '' : name.prefix.join(', '), if name.given.nil? '' : name.given.join(' '), if name.family.nil? '' : name.family].join(' ')
  #  result = name.family
  #  result = [if name.prefix.nil? '' : name.prefix.join(', '), if name.given.nil? '' : name.given.join(' '), if name.family.nil? '' : name.family].join(' ')
    #result += ', ' + name.suffix.join(', ') if name.suffix.present?
  #  sanitize(result)
  #end

  #-----------------------------------------------------------------------------

  def display_telecom(telecom)
    if !telecom.try(:value).nil?
      if !telecom.try(:system).nil?
        sanitize(telecom.try(:system) + ': ' + number_to_phone(telecom.try(:value), area_code: true))
      else
        sanitize('contact: ' + number_to_phone(telecom.try(:value), area_code: true))
      end
    end
  end

  #-----------------------------------------------------------------------------

  def display_identifier(identifier)
    sanitize("#{identifier.assigner.display}: ( #{identifier.type.text}, #{identifier.value})")
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
    'https://www.google.com/maps/search/' + html_escape(address.text)
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
    sanitize(postal_code.match(/^\d{9}$/) ?
        postal_code.strip.sub(/([A-Z0-9]+)([A-Z0-9]{4})/, '\1-\2') : postal_code)
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
