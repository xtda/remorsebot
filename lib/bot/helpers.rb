module Bot
  module Helpers
    def temp_message(event, message, time = 30)
      Thread.new do
        reply = event.send_message(message)
        sleep(time)
        event.message.delete
        reply.delete
      end
      nil
    end

    def delete_message(message, reply = nil, time = 30)
      Thread.new do
        sleep(time)
        message.delete
        reply.delete if reply
      end
      nil
    end
  end
end
