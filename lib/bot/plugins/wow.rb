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

    def self.init() end

    command :wcl, min_args: 2, max_args: 3,
                  description: 'Get warcraft logs link',
                  usage: '!wcl name realm region(optionial)' do |event, *args|
    end

    command :armory, min_args: 2, max_args: 3,
                     description: 'Search the armory for a player',
                     usage: '!armory name realm region(optionial)',
                     permission_level: Configuration.data['armory_permission_level'].to_i,
                     permission_message: false do |event, *args|
      get_character(event, *args)
    end

    def self.get_character(event, name, realm, region = 'us')
      uri = URI.encode("https://#{region}.api.battle.net/wow/character/#{realm}/#{name}?fields=items,progression,guild,achievements,talents&apikey=#{self.api_key}")
      request = RestClient.get(uri)
      character = JSON.parse(request)

      return event.respond 'Character not found!' if character['status'] == 'nok'

      parse_character(event, character, realm, region)
    end

    def self.parse_character(event, character, realm, region)
      armory_url = "http://#{region}.battle.net/wow/en/character/#{realm}/#{character['name']}/advanced"
      wowprogress_url = "http://www.wowprogress.com/character/#{region}/#{realm}/#{character['name']}"
      warcraftlogs_url = "https://www.warcraftlogs.com/character/#{region}/#{realm}/#{character['name']}"

      character.include?('guild') ? guild_string = "\n**Guild:** #{character['guild']['name']}" : guild_string = ''
      event.respond "**Details:**\n\n" \
      "**Name:** #{character['name']}" \
      "#{guild_string}" \
      "\n**Class:** #{get_class(character['class'])}" \
      "\n**Spec:** #{player_spec(character['talents'])}" \
      "\n**Faction:** #{get_faction(character['faction'])}" \
      "\n**iLVL:** #{character['items']['averageItemLevelEquipped']} (equipped) / #{character['items']['averageItemLevel']}  (max)" \
      "\n**Weapon:** #{weapon_info(character['items'], player_spec(character['talents']))}" \
      "\n\n**Progression:**\n\n#{get_progression(character['progression'])}" \
      "\n**Armory**: #{armory_url}" \
      "\n**Wowprogress**: #{wowprogress_url}" \
      "\n**Warcraft Logs**: #{warcraftlogs_url}"
    end

    def self.get_class(value)
      classes = ['Warrior', 'Paladin', 'Hunter', 'Rogue', 'Priest', \
                 'Death Knight', 'Shaman', 'Mage', 'Warlock', \
                 'Monk', 'Druid', 'Demon Hunter'].freeze
      classes.at(value - 1)
    end

    def self.get_faction(value)
      value.zero? ? 'Alliance' : 'Horde'
    end

    def self.player_spec(value)
      value.each do |key|
        if key['selected'] == true
          return key['spec']['name']
        end
      end
    end

    def self.weapon_info(items, player_spec)
      player_spec == 'protection' ? weapon_info = items['offHand']['artifactTraits'] : weapon_info = items['mainHand']['artifactTraits']
      weapon_info.map { |s| s['rank'] }.reduce(0, :+) - 3
    end

    def self.get_progression(armory_progression)
      progression = ''

      valid_raids = [
        #'The Emerald Nightmare',
        #'Trial of Valor',
        'The Nighthold',
        'Tomb of Sargeras'
      ].freeze
      armory_progression['raids'].each do |raid|
        valid_raids.each do |raids|
          if raid['name'] == raids
            raid['bosses'].each do |boss|
              if boss['mythicKills'] >= 1
                @mythic_progress += 1
              end
              if boss['heroicKills'] >= 1
                @heroic_progress += 1
              end
              if boss['normalKills'] >= 1
                @normal_progress += 1
              end
            end
          progression += "**#{raid['name']}:** #{@normal_progress} / #{raid['bosses'].length} (N) #{@heroic_progress} / #{raid['bosses'].length} (H) #{@mythic_progress} / #{raid['bosses'].length} (M)\n"
          end
        end
        @normal_progress = 0
        @heroic_progress = 0
        @mythic_progress = 0
      end
      progression
    end
  end
end
