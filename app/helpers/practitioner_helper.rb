# frozen_string_literal: true

################################################################################
#
# Practitioner Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module PractitionerHelper

  def display_qualification(qualification)
    sanitize(qualification.identifier)
  end

  #-----------------------------------------------------------------------------

  def display_code(code)
    sanitize(code.coding.display)
  end

  #-----------------------------------------------------------------------------

  def display_period(period)
    period.present? ?
            sanitize('Effective ' + period.start + ' to ' + period.end) : ''
  end

  #-----------------------------------------------------------------------------

  def display_issuer(issuer)
    sanitize(issuer.display)
  end

  #-----------------------------------------------------------------------------

  def display_photo(photo, gender, options)
      options [:class] = "img-fluid"
      image_tag(photo, options)
  end
  
end
