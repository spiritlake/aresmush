module AresMUSH
  module Scenes
    class CronEventHandler
      def on_event(event)
        config = Global.read_config("scenes", "room_cleanup_cron")
        if Cron.is_cron_match?(config, event.time)
          clear_rooms
          clear_watchers
        end
        
        if (Global.read_config("scenes", "delete_unshared_scenes"))
          config = Global.read_config("scenes", "unshared_scene_cleanup_cron")
          if Cron.is_cron_match?(config, event.time)
             delete_unshared_scenes
          end
        end
      end

      def clear_watchers
        Scene.all.each { |s| s.watchers.replace([]) }
      end
      
      def clear_rooms
        rooms = Room.all.select { |r| !!r.scene_set || !!r.scene || !r.scene_nag}
        rooms.each do |r|
          if (r.clients.empty?)
            if (r.scene_set)
              r.update(scene_set: nil)
            end
            
            if (!r.scene_nag)
              r.update(scene_nag: true)
            end
            
            if (should_stop_empty_scene(r))
              Global.logger.debug("Stopping scene in #{r.name}")
              Scenes.stop_scene(r.scene)
            end
          end
        end
      end
      
      def delete_unshared_scenes
        # Completed scenes that haven't been shared are deleted after a few days.

        warn_days = Global.read_config('scenes', 'unshared_scene_warning_days')
        delete_days = Global.read_config('scenes', 'unshared_scene_deletion_days')
        
        Scene.all.select { |s| s.completed && !s.shared }.each do |scene|
          
          elapsed_days = (Time.now - scene.date_completed) / 86400
          if (elapsed_days > delete_days  && scene.deletion_warned)
            Global.logger.info "Deleting scene #{scene.id} - #{scene.title} completed #{scene.date_completed}"
            scene.delete
          elsif (elapsed_days > warn_days && !scene.deletion_warned)
            message = t('scenes.scene_delete_warn', :id => scene.id, :title => scene.title)
            Mail.send_mail(scene.all_participant_names, t('scenes.scene_delete_warn_subject'), message, nil)
            scene.update(deletion_warned: true)
          end
        end
      end
      
      def should_stop_empty_scene(room)
        return false if !room.scene
        return true if !room.scene.temp_room
        return false
      end
    end
  end
end