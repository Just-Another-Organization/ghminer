require './lib/ja_ghminer'
require './lib/logger/logger'

set :logging, nil
logger = Log.logger
set :logger, logger

run Sinatra::Application
