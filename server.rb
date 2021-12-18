require 'sinatra'
require 'sinatra/reloader' if development?
require './src/miner'
require 'json'

before do
  content_type :json
end

if defined?(Sinatra::Reloader)
  puts 'Enabling Sinatra Reloading'
  also_reload './src'
  # dont_reload '/path/to/other/file'
  after_reload do
    puts 'Change detected: Sinatra reloaded'
  end
end

get '/health' do
  halt 200, { status: 'Alive' }.to_json
end

get '/test' do
  miner = Miner.new
  result = miner.mine
  halt 200, { result: result }.to_json
end
