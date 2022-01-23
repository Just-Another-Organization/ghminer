# frozen_string_literal: true

# Custom logger class
class Log
  def self.logger
    @_logger = Logger.new('logs/default.log') if @_logger.nil?
    @_logger
  end
end
