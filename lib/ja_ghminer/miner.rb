require 'gh-archive'
require 'yaml'
require 'rufus-scheduler'
require './lib/mongoid/model/event_model'
require './lib/logger/logger'

class Miner
  TOLERANCE_MINUTES = 60 * 10 # ten minutes necessary to ensure that GH-archive packages are present
  A_HOUR = 60 * 60

  def initialize(config_path = '')
    @config_path = config_path

    if File.file?(config_path)
      Log.logger.info("Loading configurations: #{config_path}")
      @config = YAML.load_file(config_path)
    else
      Log.logger.warn('Config file not found, using default configurations')
    end

    now = Time.now.to_i - TOLERANCE_MINUTES
    last_hour_timestamp = now - (now % 3600)
    miner_config = @config['miner']
    @starting_timestamp = miner_config['starting_timestamp'] || last_hour_timestamp - A_HOUR # last passed hour
    @ending_timestamp = miner_config['ending_timestamp'] || last_hour_timestamp
    @continuously_updated = miner_config['continuously_updated'] || false
    @max_events_number = miner_config['max_events_number'] || 0
    @last_update_timestamp = miner_config['last_update_timestamp'] || 0
    @schedule_interval = miner_config['schedule_interval'] || '1h'

    @event_model = EventModel.new

    print_configs(miner_config)
    Log.logger.info('Miner ready!')
  end

  def start
    Log.logger.info('Miner starting!')
    if @last_update_timestamp > 0 && @last_update_timestamp != @ending_timestamp
      Log.logger.info('Updating')
      update_events
    elsif @last_update_timestamp < @ending_timestamp
      Log.logger.info('Mining')
      mine(@starting_timestamp, @ending_timestamp)
    end

    if @continuously_updated
      set_continuously_update(@schedule_interval)
    end
  end

  def set_continuously_update(schedule_interval)
    scheduler = Rufus::Scheduler.new
    scheduler.every schedule_interval do
      update_events
    end
  end

  def mine (starting_timestamp, ending_timestamp)
    Log.logger.info("Mining starting timestamp: #{Time.at(starting_timestamp)}")
    Log.logger.info("Mining ending timestamp: #{Time.at(ending_timestamp)}")

    provider = GHArchive::OnlineProvider.new
    provider.include(type: 'PushEvent')
    provider.exclude(payload: nil)

    provider.each(Time.at(starting_timestamp), Time.at(ending_timestamp)) do |event|
      new_event = {
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
    end

    write_last_update_timestamp(ending_timestamp)
    update_events # Necessary in case new events were generated during the initial mining process

    Log.logger.info('Mining completed')
    Log.logger.info("Total Events: #{@event_model.get_events_number}")
  end

  def write_last_update_timestamp(timestamp)
    @last_update_timestamp = timestamp
    @config['miner']['last_update_timestamp'] = @last_update_timestamp
    File.open(@config_path, 'w') { |f| f.write @config.to_yaml }
    Log.logger.info("Last update: #{Time.at(@last_update_timestamp)}")
  end

  def update_events
    now = Time.now.to_i
    now = now - (now % 3600)
    if now - @last_update_timestamp >= A_HOUR + TOLERANCE_MINUTES
      Log.logger.info("Updating events starting from: #{@last_update_timestamp}")
      mine(@last_update_timestamp + A_HOUR, now)
      write_last_update_timestamp(now)
      resize_events_collection(@max_events_number)
      Log.logger.info('Events update completed')
    else
      Log.logger.info('Events already updated')
    end
  end

  def resize_events_collection(max_events_number)
    if max_events_number == 0
      return
    end
    events_number = @event_model.get_events_number
    if events_number > max_events_number
      Log.logger.info('Resizing events collection dimension')
      events_to_remove = events_number - max_events_number
      Log.logger.info("Removing #{events_to_remove} events")
      events = Event.all.asc('_id').limit(events_to_remove)
      events.each { |event| event.delete }
      Log.logger.info('Events collection resized')
    end
  end

  def print_configs(miner_config)
    Log.logger.info(%{

        ##### BEGIN CONFIG #####
        starting_timestamp: #{miner_config['starting_timestamp']}
        ending_timestamp: #{miner_config['ending_timestamp']}
        continuously_updated: #{miner_config['continuously_updated']}
        max_dimension: #{miner_config['max_dimension']}
        last_update_timestamp: #{miner_config['last_update_timestamp']}
        ##### END CONFIG #####

    })
  end

end
