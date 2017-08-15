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
  end
end
