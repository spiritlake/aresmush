module AresMUSH
  module Compliments
    class CompGiveCmd

      #comp <name>=<text>
      include CommandHandler
      attr_accessor :comp_msg, :scene_or_names, :scene_id, :scene, :target_names

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.scene_or_names = args.arg1
        self.comp_msg = args.arg2
      end

      def required_args
        [ self.scene_or_names, self.comp_msg ]
      end

      def handle
        targets = []
        if (self.scene_or_names.is_integer?)
          scene_id = self.scene_or_names.to_i
          scene = Scene[scene_id]
          comp_scenes = Global.read_config("compliments", "comp_scenes")
          if !scene
            client.emit_failure t('compliments.not_scene')
            return
          elsif !comp_scenes
            client.emit_failure t('compliments.comp_scenes_not_enabled')
            return
          else
            targets = scene.participants.to_a
          end
        else
          target_names = self.scene_or_names.split(" ").map { |n| InputFormatter.titlecase_arg(n) }
          target_names.each do |name|
            target = Character.named(name)
            if !target
              client.emit_failure t('compliments.invalid_name')
              return
            elsif target.name == enactor_name
              client.emit_failure t('compliments.cant_comp_self')
              return
            end
            targets << target
          end
        end

        Compliments.add_comp(targets, self.comp_msg, enactor)
        Compliments.handle_comps_given_achievement(enactor)
      end

    end
  end
end
