# frozen_string_literal: true

class Log
  def self.logger
    if @_logger.nil?
      @_logger = Logger.new('logs/default.log')
    end
    @_logger
  end
end
