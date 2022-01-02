#!/bin/ruby
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
  'Foot Trust': 0,
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

raw_events = `LIMIT=0 ./query-with-regex.rb`
events = JSON[raw_events]['result']

repo_names = []
events.each { |event|
  found = false
  content = ''
  commits = event['payload']['commits']

  commits.each { |commit|
    content += commit['message'] + ' '
  }
  technologies.each do |key, value|
    if content.downcase.include?(key.to_s.downcase)
      technologies[key] += 1
      found = true
      break
    end
  end
  unless found
    repo_names.push(event['repo']['name'])
  end
}

total = repo_names.length
progress = 0

repo_names.each { |repo_name|
  repo_url = GITHUB_BASE_URL + repo_name

  printf "Checking #{progress}/#{total}: " + repo_name + "\r"

  content = `wget -qO- #{repo_url} 2>/dev/null`

  technologies.each do |key, value|
    if content.downcase.include?(key.to_s.downcase)
      technologies[key] += 1
    end
  end
  progress += 1
}

puts technologies
