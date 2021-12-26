require 'sinatra'
require 'sinatra/reloader' if development?
require './src/miner'
require 'json'
require 'mongoid'

CONFIG_BASE_PATH = File.join(File.dirname(__FILE__), 'config')
MONGOID_CONFIG_PATH = File.join(CONFIG_BASE_PATH, 'mongoid.yml')

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
Mongoid.load!(MONGOID_CONFIG_PATH)

get '/health' do
  halt 200, { status: 'Alive' }.to_json
end

get '/test' do
  miner = Miner.new
  miner.mine
  halt 200, { result: 'OK' }.to_json
end
