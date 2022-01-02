#!/bin/ruby

require "uri"
require "json"
require "net/http"

SCHEMA = ENV['SCHEMA'] || 'http'
DOMAIN = ENV['DOMAIN'] || 'localhost'
PORT = ENV['PORT'] || '4567'
LIMIT = ENV['LIMIT'] || 0
base_url = "#{SCHEMA}://#{DOMAIN}:#{PORT}"
url = URI(base_url + '/query-regex')

keywords_regex = ''
keywords = ENV['KEYWORDS'] || ['blockchain', 'block chain']

keywords.each { |keyword| keywords_regex += "#{keyword}|" }
keywords_regex.delete_suffix!("|")

http = Net::HTTP.new(url.host, url.port)
request = Net::HTTP::Get.new(url)
request["Content-Type"] = "application/json"
request.body = JSON.dump({
                           "field": "payload.commits.message",
                           "regex": keywords_regex,
                           "limit": LIMIT
                         })

response = http.request(request)
puts response.read_body
