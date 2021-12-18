require 'sinatra'

get '/health' do
  halt 200, 'Alive'
end
