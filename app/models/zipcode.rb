################################################################################
#
# Zipcode Model
#
# Copyright (c) 2020 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Zipcode < ActiveRecord::Base

  acts_as_mappable :default_units => :miles,
                     :default_formula => :flat,
                     :distance_field_name => :distance,
                     :lat_column_name => :latitude,
                     :lng_column_name => :longitude

  #-----------------------------------------------------------------------------

  # Retrieves the zipcodes instances within the specified distance
  # of a target zipcode instance.

  def zipcodes_within(distance)
    # Use GeoKit-Rails gem
    Zipcode.within(distance, origin: [ self.latitude, self.longitude ])
  end

  #-----------------------------------------------------------------------------

  # Returns a comma-delimited string of zipcodes within the specified distance
  # of the specified zipcode string

  def self.zipcodes_within(distance, zipcode_string)
    zipcode = Zipcode.find_by_zip(zipcode_string)
    zipcode.zipcodes_within(distance).map { |z| z.zip }
  end

end
