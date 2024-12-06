module AresMUSH
  module LookingForRp
    class LookingForRpRequestHandler
      def handle(request)

        {
          chars: LookingForRp.chars_looking_for_rp
        }

      end
    end
  end
end