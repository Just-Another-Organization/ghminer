# frozen_string_literal: true

require 'gh-archive'
require 'mongoid'
require 'yaml'

class Event
  include Mongoid::Document
  field :event_id
  field :id
  embeds_one :repo
  embeds_one :payload
  field :created_at, type: Time
  index({ event_id: 1 }, { unique: true })
end

class Repo
  include Mongoid::Document
  field :id, type: String
  field :name, type: String
end

class Payload
  include Mongoid::Document
  field :push_id, type: Numeric
  field :size, type: Numeric
  field :distinct_size, type: Numeric
  field :ref, type: String
  field :head, type: String
  field :before, type: String
  embeds_many :commits
end

class Commit
  include Mongoid::Document
  field :sha, type: String
  field :message, type: String
  embeds_many :author
end

class Author
  include Mongoid::Document
  field :name, type: String
end

class Miner
  def initialize(config_path = '')
    @logger = Logger.new('logs/mining.log')
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)

    if File.file?(config_path)
      puts "Loading configurations: #{config_path}"
      @config = YAML.load_file(config_path)['miner']
    else
      puts 'Config file not found, using default configurations'
    end

    now = Time.now
    last_hour_timestamp = now - (now.to_f % 3600)
    @starting_timestamp = @config['starting_timestamp'] || last_hour_timestamp - 3600 # last passed hour
    @ending_timestamp = @config['ending_timestamp'] || last_hour_timestamp
    @continuously_updated = @config['continuously_updated'] || false
    @max_dimension = @config['max_dimension'] || 0
    @last_update_timestamp = @config['last_update_timestamp'] || 0

    print_configs
    puts 'Miner ready!'
  end

  def logger=(logger)
    @logger = logger
  end

  def mine
    block_counter = 0
    puts 'Mining....'
    @provider.each(Time.at(@starting_timestamp), Time.at(@ending_timestamp)) do |event|
      new_event = Event.new
      new_event.attributes = event.reject { |k, v| !new_event.attributes.keys.member?(k.to_s) } # remove untracked properties
      Event.create(new_event.attributes)
      block_counter += 1
    end
    puts 'Mining finish!!!'
    @logger.info("Finish mining | Total Block: #{block_counter}")
  end

  def query(query, result_limit = 0)
    puts 'Querying....'
    Event.where(query).limit(result_limit)
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
