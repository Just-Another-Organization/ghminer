require './lib/mongoid/schema/EventSchema'

def get_events_number
  Event.all.count
end

def query(query, result_limit = 0)
  @logger.info("Querying find: #{query}, limit: #{result_limit}")
  Event.where(query).limit(result_limit)
end

def query_regex(field, regex, result_limit = 0)
  @logger.info("Querying regex: #{field}, #{regex}, limit: #{result_limit}")
  regexp = Regexp.new(regex, true)
  pattern = {}
  pattern[field] = regexp
  Event.where(pattern).limit(result_limit)
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
