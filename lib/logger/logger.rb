require './lib/logger/MultiIO'

class Log
  def self.logger
    if @_logger.nil?
      log_file = File.open("logs/default.log", "a")
      @_logger = Logger.new(MultiIO.new(STDOUT, log_file))
      $stdout.sync = true
    end
    @_logger
  end
end
