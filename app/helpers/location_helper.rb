# frozen_string_literal: true

################################################################################
#
# Location Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module LocationHelper

  def display_position(position)
    sanitize([position.latitude, position.longitude].join(', ')) if position.present?
  end
  
end
