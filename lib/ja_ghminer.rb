require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongoid'
require './lib/ja_ghminer/miner'
require './lib/mongoid/model/event_model'
require './lib/logger/logger'


CONFIG_BASE_PATH = File.join(File.dirname(__FILE__), 'config')
MONGOID_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'mongoid.yml')
MINER_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'miner.yml')
ENVIRONMENT = ENV['RACK_ENV']

Log.logger.info('JA-GHMiner starting')
Mongoid.load!(MONGOID_CONFIG_PATH, ENVIRONMENT)
event_model = EventModel.new
miner = Miner.new(MINER_CONFIG_PATH)

if defined?(Sinatra::Reloader)
  Log.logger.info('Sinatra development reloading enabled')
  also_reload './src/*'
  after_reload do
    Log.logger.info('Change detected: Sinatra reloaded')
  end
end

before do
  content_type :json
end

get '/health' do
  halt 200, { status: 'Alive' }.to_json
end

get '/test' do
  result = event_model.first
  halt 200, { result: result }.to_json
end

get '/query' do
  params = JSON.parse request.body.read
  query = params['query']
  limit = params['limit']

  result = event_model.query(query, limit)
  halt 200, { result: result }.to_json
end

get '/query-regex' do
  params = JSON.parse request.body.read
  field = params['field']
  limit = params['limit']
  regex = params['regex']

  result = event_model.query_regex(field, regex, limit)
  halt 200, { result: result }.to_json
end

miner.start
