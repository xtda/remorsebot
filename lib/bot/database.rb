module Bot
  module Database
    def self.init
      if Configuration.data['bot_database_type'] == 'sqlite'
        Dir.mkdir('./data') unless File.exist?('./data')
        Dir.mkdir('./data/migrations') unless File.exist?('./data/migrations')
        FileUtils.touch "#{Configuration.data['bot_database_name']}" unless File.exist?("#{Configuration.data['bot_database_name']}")
      end

      db = Sequel.connect("#{Configuration.data['bot_database_type']}://#{Configuration.data['bot_database_name']}")

      Sequel.extension :migration

      Sequel::Migrator.run(db, './data/migrations') unless Dir['./data/migrations/*'].empty?
    end
    init
  end
end
