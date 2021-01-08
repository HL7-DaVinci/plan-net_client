require 'json'
require 'uri'
require 'pry'

class ExportController < ApplicationController

  before_action :connect_to_server

  def index
    connect_to_server 
    setexportpoll(nil)
    @request = nil 
    @outputs= []
    @exportdisabled = false
    @cancelexportdisabled = false
    @pollexportdisabled = true
  end

  def pollexport
    connect_to_server 
    export
    @exportdisabled = false
    @cancelexportdisabled = false
    @pollexportdisabled = true
  end

  def cancel
    setexportpoll(nil)
    @message = "Export Canceled"
    @outputs= []
    @exportdisabled = false
    @cancelexportdisabled = false
    @pollexportdisabled = true
  end

  # Poll for comletion of $export operation and, if complete,  display the paths to the data for export

  def export
    connect_to_server 
    exportpoll_url = session[:exportpoll]
    if exportpoll_url   #exportpoll
      response = RestClient::Request.new( :method => :get, :url => exportpoll_url, :prefer => "respond-async").execute 
      # should expect code=200 with Content-Location header with the absolute URL of an endpoint
      # then should hit the endpoint until a code = 200 is received
      # 500 error
      # 202 in progress with X-Progress header
      # 200 complete
     case response.code
      when 200
          results = JSON.parse(response.to_str)
          @request = results["request"]
          @outputs = results["output"]
          @requiresToken = results["requiresAccessToken"]
          setexportpoll(nil)
        when 202
          results = JSON.parse(response.to_str)
          progress = results[:X-Progress]
          @request = results["request"]
          @outputs = []
          @requiresToken = "In progress:   #{progress}... try again later"
      else # 500 or anything else
          @request = response.request.url  + "  failed with code = " + response.code.to_s
          @requiresToken = "Failed"
          @outputs= []
          setexportpoll(nil)
        end
    else   #export
      response = RestClient::Request.new( :method => :get, :url => server_url + "/$export", :prefer => "respond-async").execute 
      # should expect code=202 with Content-Location header with the absolute URL of an endpoint
      # then should hit the endpoint until a code = 200 is received 
      if response.code == 202   # request submitted successfully
        exportpollurl = response.headers[:content_location]
        setexportpoll(exportpollurl)
        @request = response.request.url  + "  successfuly requested"
        @requiresToken = ""
        @message = response.request.url  + " Export Successfully Requested"
      else
        @message = response.request.url  + "  Export failed with code = " + response.code.to_s
        @requiresToken = ""
        @outputs= []
        setexportpoll(nil)
        @exportdisabled = true
        @cancelexportdisabled = false
        @pollexportdisabled = false
      end
    end
  end
  #-----------------------------------------------------------------------------

    def setexportpoll(url)
    if url
      @label = "ExportPoll"
    else
      @label = "Export"
    end
    session[:exportpoll] = url
  end
end
