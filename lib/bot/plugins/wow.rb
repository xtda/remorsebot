module Bot
  class Wow < Plugin
    require 'rest-client'
    extend Discordrb::Commands::CommandContainer

    def self.about
      { name: 'Remorse WoW Armory',
        author: 'xtda',
        version: '0.0.1' }
    end

    def self.api_key
      @api_key ||= Configuration.data['bnet_api_key']
    end

    def initialize(_bot) end

    command :armory, min_args: 2, max_args: 3, 
            description: 'Search the armory for a player', 
            usage: '!armory name realm region(option)' do |event, *args|
    end
  end
end