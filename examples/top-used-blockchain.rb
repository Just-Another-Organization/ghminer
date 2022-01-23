#!/bin/ruby
# frozen_string_literal: true

require 'json'

GITHUB_BASE_URL = 'https://github.com/'

technologies = {
  'XDC Network': 0,
  'IBM Blockchain': 0,
  'Stellar': 0,
  'MultiChain': 0,
  'Tron': 0,
  'Tezos': 0,
  'Hyperledger Fabric': 0,
  'Hyperledger Sawtooth': 0,
  'Hyperledger Iroha': 0,
  'Hyperledger Besu': 0,
  'Hyperledger Burrow': 0,
  'Hyperledger Indy': 0,
  'Hedera Hashgraph': 0,
  'Food Trust': 0,
  'Ripple': 0,
  'Quorum': 0,
  'Corda': 0,
  'EOS': 0,
  'Eosio': 0,
  'OpenChain': 0,
  'Ethereum': 0,
  'Dragonchain': 0,
  'NEO': 0,
  'Bitcoin': 0
}

options = ENV['OPTIONS']

if defined?(ENV['KEYWORDS'])
  keywords = ENV['KEYWORDS']
else
  technologies.each do |key, _value|
    keywords = "#{keywords} #{key}"
  end
end

raw_events = `#{options} KEYWORDS='#{keywords}' ./query-with-regex.rb`
events = JSON[raw_events]['result']

repo_names = []
events.each do |event|
  found = false
  content = ''
  commits = event['payload']['commits']

  commits.each do |commit|
    content += "#{commit['message']} "
  end
  technologies.each do |key, _value|
    next unless content.downcase.include?(key.to_s.downcase)

    technologies[key] += 1
    found = true
    break
  end
  repo_names.push(event['repo']['name']) unless found
end

total = repo_names.length
progress = 0

repo_names.each do |repo_name|
  repo_url = GITHUB_BASE_URL + repo_name

  printf "Checking #{progress}/#{total}: #{repo_name}\r"

  content = `wget -qO- #{repo_url} 2>/dev/null`

  technologies.each do |key, _value|
    technologies[key] += 1 if content.downcase.include?(key.to_s.downcase)
  end
  progress += 1
end

puts technologies
