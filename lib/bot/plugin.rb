module Bot
  include Helpers
  class Plugin
    def self.plugins
      @plugins ||= []
    end

    def self.inherited(subclass)
      @plugins ||= []

      @plugins << subclass
    end

    def initialize
      raise "#{self.class.name} doesn't implement `initialize`!"
    end
  end
end
