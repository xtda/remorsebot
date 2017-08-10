module Bot
  class Core < Plugin
    extend Discordrb::Commands::CommandContainer
    def self.about
      { name: 'Remorse Bot Core',
        author: 'xtda',
        version: '0.0.1' }
    end

    def initialize(bot)
      bot.set_user_permission(Configuration.data['discord_owner_id'], 999)
    end

    command :id do |event|
      event.user.id
    end

    command :plugins do |event|
      plugins = ''
      Plugin.plugins.each do |plugin|
        plugins += plugin.about.to_s
      end
      return event.respond "Plugins loaded: #{plugins}"
    end
  end
end