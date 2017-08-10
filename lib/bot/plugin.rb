module Bot
  class Plugin
    def self.plugins
      @plugins ||= []
    end

    def self.inherited(klass)
      @plugins ||= []

      @plugins << klass
    end

    def init(_bot)
      raise "#{self.class.name} doesn't implement `init`!"
    end
  end
end