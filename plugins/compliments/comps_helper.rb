module AresMUSH
  module Compliments




    def self.handle_comps_given_achievement(char)
      char.update(comps_given: char.comps_given + 1)
      [ 1, 10, 20, 50, 100 ].reverse.each do |count|
        if (char.comps_given >= count)
          Achievements.award_achievement(char, "gave_comps", count)
        end
      end
    end

    def self.give_comp_luck(target, comper_char)
      target_luck_amount = Global.read_config("compliments", "target_luck_amount")
      comper_luck_amount = Global.read_config("compliments", "comper_luck_amount")
      FS3Skills.modify_luck(target, target_luck_amount)
      FS3Skills.modify_luck(comper_char, comper_luck_amount)
    end

    def self.notify_of_comp(target, comper_char)
      message = t('compliments.has_left_comp', :from => comper_char.name)
      Login.emit_if_logged_in target, "%xc#{message}%xn"
      Login.notify(target, :comp, message, target.id)
    end

    def self.add_comp(targets, msg, comper_char)
      target_names = []
      targets.each do |target|
        if target == comper_char
          #skip self if in a comp'd scene
        else
          Comps.create(character: target, comp_msg: msg, from: comper_char.name)
        give_luck = Global.read_config("compliments", "give_luck")
        if give_luck
          Compliments.give_comp_luck(target, comper_char)
        end
        target_names << target.name
        Compliments.notify_of_comp(target, comper_char)
        end
      end
      success_msg = t('compliments.left_comp', :name =>  target_names.join(", "))
      Login.emit_if_logged_in(comper_char, success_msg)
    end

    def self.get_comps(char, page=1)
      list = char.comps
      list = list.to_a.sort_by { |c| c.created_at }.reverse
      paginator = Paginator.paginate(list, page, 5)
      if (paginator.out_of_bounds?)
        return { comps: [], pages: [1] }
      end
      {
        comps: paginator.page_items.map { |c| {
          from: c.from,
          msg:  Website.format_markdown_for_html(c.comp_msg),
          date: OOCTime.format_date_for_entry(c.created_at)
        }},
        pages: paginator.total_pages.times.to_a.map { |i| i+1 }
    }
    end

  end
end
