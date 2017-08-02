require 'rubygems'
require 'bundler/setup'

require 'discordrb'
require 'json'
require 'yaml'

module Bot
  require_relative 'bot/configuration.rb'

  Configuration.init

  bot = Discordrb::Commands::CommandBot.new token: Configuration.data['discord_token'],
                                            client_id: Configuration.data['discord_application_id'],
                                            prefix: Configuration.data['command_prefix']

  Dir['./lib/plugins/*.rb'].each do |plugin|
    require plugin
    bot.include! plugin
    plugin.init(bot)
  end

  bot.run :async
  gets
  bot.stop
end
