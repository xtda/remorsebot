module Bot
  class Wow < Plugin
    extend Discordrb::Commands::CommandContainer

    def self.about
      { name: 'Remorse WoW Armory',
        author: 'xtda',
        version: '0.0.1' }
    end

    def initialize(_bot)
    end
  end
end