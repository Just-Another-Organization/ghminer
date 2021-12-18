require 'gh-archive'

class Miner
  def initialize
    @provider = GHArchive::OnlineProvider.new
    @provider.include(type: 'PushEvent')
    @provider.exclude(payload: nil)

    puts "Miner ready!"
  end

  def mine
    result = []
    @provider.each(Time.gm(2021, 1, 1, 0, 0, 0), Time.gm(2021, 1, 1, 2, 0, 0)) do |event|
      result.push(event['payload']['commits'].map { |c| c['author']['name'] }.uniq.join(", "))
    end
    result
  end
end
