module AresMUSH
  module Compliments
    class AddCompHandler
      def handle(request)
        puts request.args
        comp_msg = request.args[:comp_msg]
        char_name_or_id = request.args[:char_id]
        char = Character.find_one_by_name(char_name_or_id)
        comper_id = request.auth[:id]
        Compliments.add_comp([char], comp_msg, Character[comper_id])
        error = Website.check_login(request)
        return error if error
        if comper_id == char_name_or_id
          return { error: t('compliments.cant_comp_self') }
        end
        {
        }
      end
    end
  end
end