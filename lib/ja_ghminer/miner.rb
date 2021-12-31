require 'gh-archive'
require 'mongoid'
require 'yaml'
require 'logger'
require 'rufus-scheduler'

class Event
  include Mongoid::Document
  field :event_id, type: Numeric
  field :id, type: String
  embeds_one :repo
  embeds_one :payload
  field :created_at, type: Time

  index({ event_id: 1 }, { unique: true, name: "event_id_index" })
  index({ id: 1 }, { unique: true, name: "id_index" })
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
  TOLERANCE_MINUTES = 60 * 10 # ten minutes
  A_HOUR = 60 * 60

  def initialize(config_path = '')
    @config_path = config_path
    # @logger = Logger.new('logs/mining.log')
    @logger = Logger.new(STDOUT)
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)

    if File.file?(config_path)
      @logger.info("Loading configurations: #{config_path}")
      @config = YAML.load_file(config_path)
    else
      @logger.info('Config file not found, using default configurations')
    end

    now = Time.now.to_i
    last_hour_timestamp = now - (now % 3600) - TOLERANCE_MINUTES
    miner_config = @config['miner']
    @starting_timestamp = miner_config['starting_timestamp'] || last_hour_timestamp - A_HOUR # last passed hour
    @ending_timestamp = miner_config['ending_timestamp'] || last_hour_timestamp
    @continuously_updated = miner_config['continuously_updated'] || false
    @max_dimension = miner_config['max_dimension'] || 0
    @last_update_timestamp = miner_config['last_update_timestamp'] || 0
    @schedule_interval = miner_config['schedule_interval'] || '1h'

    print_configs
    @logger.info('Miner ready!')

    if @last_update_timestamp > @starting_timestamp
      @starting_timestamp = @last_update_timestamp
    end

    mine(Time.at(@starting_timestamp), Time.at(@ending_timestamp))

    if @continuously_updated
      set_continuously_update
    end
  end

  def set_continuously_update
    @scheduler = Rufus::Scheduler.new
    @scheduler.every @schedule_interval do
      update_events
    end
  end

  def logger=(logger)
    @logger = logger
  end

  def mine (starting_timestamp, ending_timestamp)
    events_counter = get_events_number

    @logger.info('Mining started')
    @logger.info("Stored events: #{events_counter}")

    @provider.each(Time.at(starting_timestamp), Time.at(ending_timestamp)) do |event|
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

    update_events # Necessary in case new events were generated during the initial mining process

    @logger.info('Mining completed')
    @logger.info("Total Events: #{events_counter}")
  end

  def write_last_update_timestamp
    @last_update_timestamp = Time.now.to_i
    @config['miner']['last_update_timestamp'] = @last_update_timestamp
    File.open(@config_path, 'w') { |f| f.write @config.to_yaml }
    @logger.info("Last update: #{Time.at(@last_update_timestamp)}")
  end

  def update_events
    if @last_update_timestamp != 0 && @last_update_timestamp < Time.now.to_i - A_HOUR
      @logger.info("Updating events starting from: #{@last_update_timestamp}")
      mine(@last_update_timestamp, Time.now)
      @logger.info('Events update completed')
    else
      @logger.info('Events already updated')
    end
    write_last_update_timestamp
  end

  def get_events_number
    Event.all.count
  end

  def query(query, result_limit = 0)
    @logger.info("Querying find: #{query}, limit: #{result_limit}")
    Event.where(query).limit(result_limit)
  end

  def find(query)
    @logger.info("Querying find: #{query}")
    Event.find(query)
  end

  def get_all
    @logger.info('Querying all')
    Event.all
  end

  def first
    @logger.info('Querying first')
    Event.first
  end

  def print_configs
    @logger.info(%{
##### BEGIN CONFIG #####
starting_timestamp: #{@starting_timestamp}
ending_timestamp: #{@ending_timestamp}
continuously_updated: #{@continuously_updated}
max_dimension: #{@max_dimension}
last_update_timestamp: #{@last_update_timestamp}
##### END CONFIG #####

})
  end

end
