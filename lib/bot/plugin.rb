module Bot
  class Plugin
    extend Bot::Helpers
    def self.plugins
      @plugins ||= []
    end

    def self.inherited(subclass)
      @plugins ||= []

      @plugins << subclass
    end
  end
end
