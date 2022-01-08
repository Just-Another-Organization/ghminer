require './lib/mongoid/schema/event_schema'
require './lib/logger/logger'

class EventModel
  def get_events_number
    Event.all.count
  end

  def query(query, result_limit = 0)
    Log.logger.info("Querying find: #{query}, limit: #{result_limit}|")
    Event.where(query).limit(result_limit)
  end

  def query_regex(field, regex, result_limit = 0)
    Log.logger.info("Querying regex: #{field}, #{regex}, limit: #{result_limit}|")
    regexp = Regexp.new(regex, true)
    pattern = {}
    pattern[field] = regexp
    Event.where(pattern).limit(result_limit)
  end

  def find(query)
    Log.logger.info("Querying find: #{query}|")
    Event.find(query)
  end

  def get_all
    Log.logger.info('Querying all|')
    Event.all
  end

  def first
    Log.logger.info('Querying first|')
    Event.first
  end
end
