################################################################################
#
# ClientConnections Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ClientConnections

  @@clients = Hash.new

  def self.set(id, url)
    begin
      client = FHIR::Client.new(url)
      client.use_r4
      FHIR::Model.client = client
    rescue
      return nil
    end
    @@clients[id] = client
  end

  #-----------------------------------------------------------------------------

  def self.get(id)
    @@clients[id]
  end

end