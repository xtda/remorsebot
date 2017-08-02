module Bot
  # Attempt load yaml based config and throw error if file is not found or invalid
  module Configuration
    def self.init
      puts "[ERROR] Can't find the configuration file." unless
      File.exist?('./config/bot.yml')

      @config = begin
        YAML.load_file('./config/bot.yml')
      rescue ArgumentError => e
        puts "[ERROR] Can't parse YAML."
        puts "[ERROR] #{e.message}"
        exit
      end
    end

    def self.data
      @config
    end
  end
end
