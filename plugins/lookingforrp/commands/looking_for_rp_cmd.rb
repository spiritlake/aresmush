module AresMUSH
  module LookingForRp
    class LookingForRpCommand
      include CommandHandler

      attr_accessor :duration

      def parse_args
        self.duration = cmd.args || 1
      end

      def check_errors
        return "You can't set yourself 'Looking for RP' for longer than 3 hours." if duration.to_i > 3
      end
      def handle
        LookingForRp.set(enactor, self.duration.to_i)
        client.emit_success t('lookingforrp.set', :duration => self.duration)
      end
    end
  end
end
