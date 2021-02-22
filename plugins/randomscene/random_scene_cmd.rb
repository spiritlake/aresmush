module AresMUSH
  module Randomscene
    class RandomSceneCmd
    # shield/off <shield>
      include CommandHandler

      attr_accessor :names

      def parse_args
        if cmd.args
          names = list_arg(cmd.args)
          self.names = names.concat [enactor.name]
        else
          self.names = [enactor.name]
        end
      end



      def handle
        self.names.each do |name|
          char = Character.find_one_by_name(name)
          if (!char)
            client.emit_failure t('page.invalid_name')
            return
          end
        end
        type = rand(2)

        if type == 0
          scenario = Global.read_config("randomscene", "scenarios")
          msg = t('randomscene.random_scenario', :scenario => scenario.sample)
        elsif type == 1
          excluded_areas = Global.read_config("randomscene", "excluded_areas")
          room_list = Room.all.select { |r| (r.room_type == "IC" && r.area && !excluded_areas.include?(r.area_name)) }
          room = room_list.sample
          word_list = Global.read_config("randomscene", "words")
          prompts = ""
          self.names.each do |name|
            prompts = prompts + t('randomscene.prompt_piece', :name => name.titlecase, :word =>  word_list.sample)
          end
          msg = t('randomscene.prompt_total', :prompts => prompts, :area => room.area.name, :room => room.name)
        elsif type == 2
          npc_list = Global.read_config("randomscene", "npcs")
          action_list = Global.read_config("randomscene", "actions")
          msg = t('randomscene.npc_scenario', :npc => npc_list.sample, :action => action_list.sample)
        end
        self.names.each do |name|
          char = Character.named(name)
          Login.emit_if_logged_in(char, msg)
        end

      end

    end
  end
end
