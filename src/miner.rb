# frozen_string_literal: true

require 'gh-archive'
require 'mongoid'
require 'logger'

class Commit
  include Mongoid::Document
  field :author, type: String
  field :message, type: String
  field :url, type: String
end

class Miner

  def initialize
    @logger = Logger.new('logs/mining.log')
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)
    puts 'Miner ready!'
  end

  def logger=(logger)
    @logger = logger
  end

  def mine
    block_counter = 0
    puts 'Mining....'
    @logger.info("Start mining")

    @provider.each(Time.gm(2021, 1, 1, 0, 0, 0), Time.gm(2021, 1, 1, 2, 0, 0)) do |event|
      event['payload']['commits'].map do |c|
        Commit.create({ author: c['author']['name'], message: c['message'], url: c['url'] })
      end
      block_counter += 1
    end
    puts 'Mining finish!!!'
    @logger.info("Finish mining | Total Block: #{block_counter}")
  end
end
