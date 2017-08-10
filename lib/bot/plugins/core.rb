module Bot
  class Core < Plugin
    extend Discordrb::Commands::CommandContainer
    def self.info
      { name: 'Remorse Bot Core',
        author: 'xtda',
        version: '0.0.1' }
    end

    def self.init(bot)
      bot.set_user_permission(Configuration.data['discord_owner_id'], 999)
    end

    command :id do |event|
      event.user.id
    end
    
    command :plugins do |event|
      plugins = ''
      Plugin.plugins.each do |plugin|
        plugins += "#{plugin.info}"
      end
      return event.respond "Plugins loaded: #{plugins}"
    end
  end
end