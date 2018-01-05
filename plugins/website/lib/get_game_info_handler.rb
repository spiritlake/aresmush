module AresMUSH
  module Website
    class GetGameInfoRequestHandler
      def handle(request)
        disabled = {}
        Global.read_config('plugins', 'disabled_plugins').each do |p|
          disabled[p] = true
        end
        
        {
          type: 'game',
          id: 1,
          name: Global.read_config('game', 'name'),
          host: Global.read_config('server', 'hostname'),
          port: Global.read_config('server', 'port'),
          website_tagline: Global.read_config('website', 'website_tagline'),
          website_welcome: WebHelpers.format_markdown_for_html(Global.read_config('website', 'website_welcome')),
          onlineCount: Global.client_monitor.logged_in.count,
          ictime: ICTime.ic_datestr(ICTime.ictime),
          date_entry_format: Global.read_config('date_and_time', 'date_entry_format_help').upcase,
          disabled_plugins: disabled,
          who_count: Global.client_monitor.logged_in.count,
          scene_count: Scene.all.select { |s| !s.completed }.count,
          roster_enabled: Idle.roster_enabled?
        } 
      end
    end
  end
end