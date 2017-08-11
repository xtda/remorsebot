module Bot
  class Core < Plugin
    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer

    def self.about
      { name: 'Remorse Bot Core',
        author: 'xtda',
        version: '0.0.1' }
    end

    def initialize() end

    command :id do |event|
      event.user.id
    end

    ready do |event|
      event.bot.set_user_permission(Configuration.data['discord_owner_id'].to_i, 999)

      Configuration.data['roles'].each do |roleid, level|
        event.bot.set_role_permission(roleid.to_i, level)
      end
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