#!/bin/ruby
# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'

SCHEMA = ENV['SCHEMA'] || 'http'
DOMAIN = ENV['DOMAIN'] || 'localhost'
PORT = ENV['PORT'] || '4567'
LIMIT = ENV['LIMIT'] || 0
URL = ENV['URL']
AUTH = ENV['AUTH']

if defined?(URL)
  base_url = URL
else
  base_url = "#{SCHEMA}://#{DOMAIN}:#{PORT}"
end

url = URI("#{base_url}/query-regex")

keywords_regex = ''
if defined?(ENV['KEYWORDS'])
  keywords = ENV['KEYWORDS'].split()
else
  keywords = ['blockchain', 'DLT', 'Distributed Ledger', 'Hyperledger']
end

keywords.each { |keyword| keywords_regex += "#{keyword}|" }
keywords_regex.delete_suffix!('|')

http = Net::HTTP.new(url.host, url.port)

if base_url.start_with?('https')
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

request = Net::HTTP::Get.new(url)
request['Content-Type'] = 'application/json'

request.body = JSON.dump({
                           "field": 'payload.commits.message',
                           "regex": keywords_regex,
                           "limit": LIMIT
                         })

response = http.request(request)
puts response.read_body
