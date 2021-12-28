# frozen_string_literal: true

require 'gh-archive'
require 'mongoid'
require 'yaml'

class Commit
  include Mongoid::Document
  field :sha, type: String
  field :author do
    field :email, type: String
    field :name, type: String
  end
  field :message, type: String
  field :distinct, type: Boolean
  field :url, type: String
end

class Miner
  def initialize(config_path = '')
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)

    if File.file?(config_path)
      puts "Loading configurations: #{config_path}"
      @config = YAML.load_file(config_path)['miner']
    else
      puts 'Config file not found, using default configurations'
    end

    @starting_timestamp = @config['starting_timestamp'] || Time.now - 3600 # last hour
    @ending_timestamp = @config['ending_timestamp'] || Time.now
    @continuously_updated = @config['continuously_updated'] || false
    @max_dimension = @config['max_dimension'] || 0
    @last_update_timestamp = @config['last_update_timestamp'] || 0

    print_configs
    puts 'Miner ready!'
  end

  def mine
    puts 'Mining....'
    @provider.each(Time.at(@starting_timestamp), Time.at(@ending_timestamp)) do |event|
      puts event
      break
    end
    puts 'Mining finish!!!'
  end

  def query(query, result_limit = 0)
    puts 'Querying....'
    Commit.where(query).limit(result_limit)
  end

  def print_configs
    puts %{
##### BEGIN CONFIG #####
starting_timestamp: #{@starting_timestamp}
ending_timestamp: #{@ending_timestamp}
continuously_updated: #{@continuously_updated}
max_dimension: #{@max_dimension}
last_update_timestamp: #{@last_update_timestamp}
##### END CONFIG #####

}
  end

end
