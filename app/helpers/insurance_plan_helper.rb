# frozen_string_literal: true

################################################################################
#
# Insurance Plan Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module InsurancePlanHelper

  def display_owned_by(owned_by)
    owned_by.present? ? sanitize(owned_by.display) : 'Not available'
  end

  #-----------------------------------------------------------------------------

  def display_administered_by(administered_by)
    administered_by.present? ? sanitize(administered_by.display) : 'Not available'
  end

  #-----------------------------------------------------------------------------

  def display_coverage_area(coverage_area)
    coverage_area.present? ? display_list(coverage_area) : 'Not available'
  end
  
end
