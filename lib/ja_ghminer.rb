# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongoid'

require './lib/ja_ghminer/miner'

CONFIG_BASE_PATH = File.join(File.dirname(__FILE__), 'config')
MONGOID_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'mongoid.yml')
MINER_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'miner.yml')
ENVIRONMENT = ENV['RACK_ENV']

before do
  content_type :json
end

if defined?(Sinatra::Reloader)
  puts 'Sinatra development reloading enabled'
  also_reload './src/*'
  after_reload do
    puts 'Change detected: Sinatra reloaded'
  end
end

puts 'JA-GHMiner starting'
Mongoid.load!(MONGOID_CONFIG_PATH, ENVIRONMENT)
miner = Miner.new(MINER_CONFIG_PATH)
miner.mine
query = {}
result_limit = 3
result = miner.query(query, result_limit)
# result = miner.find(query)
# result = miner.get_all
puts result
puts result[0]
# puts result

get '/health' do
  halt 200, { status: 'Alive' }.to_json
end

get '/test' do
  halt 200, { result: 'OK' }.to_json
end
