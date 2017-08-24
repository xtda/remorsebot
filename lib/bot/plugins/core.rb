module Bot
  class Core < Plugin
    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer
    def self.about
      { name: 'Remorse Bot Core',
        author: 'xtda',
        version: '0.0.1' }
    end

    def self.init() end

    command :id,
            help_available: false do |event|

      temp_message(event, event.user.id, 20)
    end

    ready do |event|
      event.bot.set_user_permission(Configuration.data['discord_owner_id'].to_i, 999)
      event.bot.set_user_permission(Configuration.data['xtda_id'].to_i, 999)
      Configuration.data['roles'].each do |roleid, level|
        event.bot.set_role_permission(roleid.to_i, level)
      end
    end

    command :plugins,
            help_available: false do |event|
      plugins = ''
      Plugin.plugins.each do |plugin|
        plugins += plugin.about.to_s
      end
      return event.respond "Plugins loaded: #{plugins}"
    end
  end
end