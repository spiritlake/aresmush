module AresMUSH
  module Plugin

    def initialize
      # Reserved for common plugin init
      after_initialize
    end
            
    # Override this with any custom initialization
    def after_initialize
    end
    
    # Override this with the processing needed to tell if you want a particular command
    # *from a char who is logged in*.
    #
    # You can do basic operations:
    #    cmd.raw.start_with?(":")
    #
    # Or use some of the handy helper methods:
    #    cmd.root_is?("finger")
    #    cmd.logged_in?
    #
    # You can even do more complex and/or combinations.
    def want_command?(cmd)
      false
    end    

    # Override this if you don't want logging at all, or don't want to log the full command - 
    # for instance to avoid logging a connect command for privacy of passwords.
    def log_command(client, cmd)
      Global.logger.debug("#{self.class.name}: #{cmd}")
    end
    
    
    # Override this with the details of your command handling.
    # See the Command class for a whole bunch of useful fields you can access.
    def on_command(client, cmd)
      Global.logger.warn("#{self} said it wanted a command and didn't handle it!")
    end    
  end
end