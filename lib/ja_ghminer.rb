# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongoid'

require './lib/ja_ghminer/miner'


CONFIG_BASE_PATH = File.join('config')
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
