require 'gh-archive'
require 'mongoid'
require 'yaml'

class Event
  include Mongoid::Document
  field :event_id, type: Numeric
  field :id, type: String
  embeds_one :repo
  embeds_one :payload
  field :created_at, type: Time

  # index({ event_id: 1}, { unique: true, name: "event_id_index"})
  # index({ id: 1}, { unique: true, name: "id_index"})
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
  embeds_one :author
end

class Author
  include Mongoid::Document
  field :name, type: String
end

class Miner
  TOLERANCE_MINUTES = 60 * 5 # five minutes

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
    last_hour_timestamp = now - (now.to_f % 3600) - TOLERANCE_MINUTES
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
    events_counter = 1
    puts 'Mining....'
    @provider.each(Time.at(@starting_timestamp), Time.at(@ending_timestamp)) do |event|
      new_event = {
        event_id: events_counter,
        id: event['id'],
        repo: {
          id: event['repo']['id'],
          name: event['repo']['name']
        },
        payload: {
          push_id: event['payload']['push_id'],
          size: event['payload']['size'],
          distinct_size: event['payload']['distinct_size'],
          ref: event['payload']['ref'],
          head: event['payload']['head'],
          before: event['payload']['before'],
          commits:
            event['payload']['commits'].map do |commit|
              {
                sha: commit['sha'],
                message: commit['message'],
                author: {
                  name: commit['author']['name']
                }
              }
            end
        },
        created_at: event['created_at']
      }

      Event.create(new_event)
      events_counter += 1
    end

    puts 'Mining finish!!!'
    @logger.info("Finish mining | Total Block: #{events_counter}")
  end

  def query(query, result_limit = 0)
    puts 'Querying....'
    Event.where(query).limit(result_limit)
  end

  def find(query)
    puts 'Querying....'
    Event.find(query)
  end

  def get_all
    puts 'Querying....'
    Event.all
  end

  def first
    puts 'Querying....'
    Event.first
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
