module Bot
  module Database
    def self.init
      Dir.mkdir('./data') unless File.exist?('./data')
      Dir.mkdir('./data/migrations') unless File.exist?('./data/migrations')
      FileUtils.touch "data/#{Configuration.data['bot_database_name']}" unless File.exist?("data/#{Configuration.data['bot_database_name']}")

      db = Sequel.connect("sqlite://data/#{Configuration.data['bot_database_name']}")

      Sequel.extension :migration

      Sequel::Migrator.run(db, './data/migrations') unless Dir['./data/migrations/*'].empty?
    end
    init
  end
end
