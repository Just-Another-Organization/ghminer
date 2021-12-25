require 'sinatra'
require 'sinatra/reloader' if development?
require './src/miner'
require 'json'
require 'mongoid'


before do
  content_type :json
end

if defined?(Sinatra::Reloader)
  puts 'JA_MINER'
  Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))
  puts 'Enabling Sinatra Reloading'
  also_reload './src/*'
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
  miner.mine
  halt 200, { result: 'OK' }.to_json
end
