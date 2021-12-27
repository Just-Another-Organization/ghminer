# frozen_string_literal: true

require 'gh-archive'
require 'mongoid'


class Commit
  include Mongoid::Document
  field :author, type: String
end

class Miner
  def initialize
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)
    puts 'Miner ready!'
  end

  def mine
    puts 'Mining....'
    @provider.each(Time.gm(2021, 1, 1, 0, 0, 0), Time.gm(2021, 1, 1, 2, 0, 0)) do |event|
      event['payload']['commits'].map { |c| Commit.create({ author: c['author']['name'] }) }
    end
    puts 'Mining finish!!!'
  end
end
