module AresMUSH
  module Compliments
    class GetCompsRequestHandler
      def handle(request)
        page = (request.args[:page] || "1").to_i
        char_name_or_id = request.args[:char_id]
        char = Character.find_one_by_name(char_name_or_id)
        puts "Char: #{char} Page #{page}"
        puts Compliments.get_comps(char, page)
        Compliments.get_comps(char, page)

      end
    end
  end
end