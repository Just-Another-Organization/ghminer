require 'gh-archive'

class Miner
  def initialize
    @provider = OnlineGHAProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)

    puts "Miner ready!"
  end

  def mine
    @provider.each(Time.gm(2015, 1, 1), Time.gm(2015, 1, 2)) do |event|
      result = event['payload']['commits'].map { |c| c['author']['name'] }.uniq.join(", ")
      puts result
      return result
    end
  end
end
