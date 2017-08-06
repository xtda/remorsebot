module Bot
  module Database
    def self.init
      Dir.mkdir('./data') unless File.exist?('./data')
      Dir.mkdir('./data/migrations') unless File.exist?('./data/migrations')
      FileUtils.touch "data/remorse.db" unless File.exist?("data/remorse.db")

      #db = Sequel.connect('sqlite://data/billy.db')

      #Sequel.extension :migration

      #Sequel::Migrator.run(db, './data/migrations')
    end
  self.init
    end
end
