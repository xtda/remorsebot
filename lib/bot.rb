require 'rubygems'
require 'bundler/setup'

require 'discordrb'
require 'json'
require 'yaml'
require 'fileutils'

require 'sequel'
require 'sqlite3'

# Bot main module
# loads required libaries creates a bot loads plugins starts bot

module Bot
  require_relative 'bot/configuration.rb'
  require_relative 'bot/database.rb'
  require_relative 'bot/plugin.rb'

  bot = Discordrb::Commands::CommandBot.new token: Configuration.data['discord_token'],
                                            client_id: Configuration.data['discord_application_id'],
                                            prefix: Configuration.data['command_prefix']

  Dir['./lib/bot/plugins/*.rb'].each { |p| require p }

  Plugin.plugins.each do |plugin|
    bot.include! plugin
    plugin.new bot
  end

  bot.run :async
  gets
  bot.stop
end
