require 'rubygems'
require 'bundler/setup'

require 'discordrb'
require 'json'
require 'yaml'
require 'fileutils'

module Bot
  require_relative 'bot/configuration.rb'
  require_relative 'bot/database.rb'

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
