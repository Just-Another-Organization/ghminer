require 'sinatra'
require './src/miner'
require 'json'

before do
  content_type :json
end

get '/health' do
  halt 200, { status: 'Alive' }.to_json
end

get '/test' do
  miner = Miner.new
  result = miner.mine
  halt 200, { result: result }.to_json
end
