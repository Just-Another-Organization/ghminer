# frozen_string_literal: true
require 'gh-archive'
require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

class Miner
  def initialize
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)
    @client = Mongo::Client.new('mongodb://jaminer:password@mongodb:27017/ja-archive?authSource=admin')
    @collection = @client[:document]
    puts 'Miner ready!'
  end

  def mine
    puts 'Mining....'
    @provider.each(Time.gm(2021, 1, 1, 0, 0, 0), Time.gm(2021, 1, 1, 1, 0, 0)) do |event|
      event['payload']['commits'].map { |c| @collection.insert_one({ :_id => BSON::ObjectId.new, :author => c['author'].name }) }
    end
    @client.close
    puts 'Mining finish!!!'
  end
end
