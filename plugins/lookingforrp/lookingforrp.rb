$:.unshift File.dirname(__FILE__)

module AresMUSH
     module LookingForRp

    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config("lookingforrp", "shortcuts")
    end

    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when 'lookingforrp'
        return LookingForRpCommand
      end
      nil
    end

    def self.get_event_handler(event_name)
      case event_name
      when "CronEvent"
        return LookingForRpCronEventHandler
      end
      nil
    end

    def self.get_web_request_handler(request)
      nil
    end

  end
end
