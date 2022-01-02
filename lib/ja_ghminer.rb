require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongoid'
require './lib/ja_ghminer/miner'
require './lib/mongoid/model/Event'

CONFIG_BASE_PATH = File.join(File.dirname(__FILE__), 'config')
MONGOID_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'mongoid.yml')
MINER_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'miner.yml')
ENVIRONMENT = ENV['RACK_ENV']

puts 'JA-GHMiner starting'
Mongoid.load!(MONGOID_CONFIG_PATH, ENVIRONMENT)
miner = Miner.new(MINER_CONFIG_PATH)

if defined?(Sinatra::Reloader)
  puts 'Sinatra development reloading enabled'
  also_reload './src/*'
  after_reload do
    puts 'Change detected: Sinatra reloaded'
  end
end

before do
  content_type :json
end

get '/health' do
  halt 200, { status: 'Alive' }.to_json
end

get '/test' do
  result = Event.first
  halt 200, { result: result }.to_json
end

get '/query' do
  params = JSON.parse request.body.read
  query = params['query']
  limit = params['limit']

  puts query
  puts limit

  result = Event.query(query, limit)
  halt 200, { result: result }.to_json
end

get '/query-regex' do
  params = JSON.parse request.body.read
  field = params['field']
  limit = params['limit']
  regex = params['regex']

  result = Event.query_regex(field, regex, limit)
  halt 200, { result: result }.to_json
end

miner.start
