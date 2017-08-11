module Bot
  module Helpers
    def officer?(event)
      event.user.on(event.channel.server).role?(Configuration.data['officer_id'])
    end
  end
end