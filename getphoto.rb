require "rubygems"
require "net/https"
require "uri"
require "json"


uri = URI.parse("https://randomuser.me/api?format=json&gender=male")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Get.new(uri.request_uri)


res = http.request(request)
response = JSON.parse(res.body)
photo = response["results"].first["picture"]["large"]
puts photo
