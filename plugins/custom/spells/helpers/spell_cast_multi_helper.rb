module AresMUSH
  module Custom

    def self.cast_multi_heal(caster, caster_combat, target_string, spell)
      succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
      if succeeds == "%xgSUCCEEDS%xn"
        targets = Custom.parse_spell_targets(target_string, caster.combat)
        targets.each do |t|
          target = FS3Combat.find_named_thing(t, caster)
          return t('custom.cant_heal_dead') if (target.dead)
          wound = FS3Combat.worst_treatable_wound(target)
          heal_points = Global.read_config("spells", spell, "heal_points")

          if (wound)
            FS3Combat.heal(wound, heal_points)
            FS3Combat.emit_to_combat caster.combat, t('custom.cast_heal', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name, :points => heal_points)
          else
            FS3Combat.emit_to_combat caster.combat, t('custom.cast_heal_no_effect', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name)
          end
        end
      else
        FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

    # def self.cast_multi_subdue(caster, caster_combat, target_string, spell)
    #   succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
    #   if succeeds == "%xgSUCCEEDS%xn"
    #     targets = Custom.parse_spell_targets(target_string, caster.combat)
    #     targets.each do |t|
    #       target = FS3Combat.find_named_thing(t, caster)

    def self.cast_multi_revive(caster, caster_combat, target_string, spell)
      succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
      if succeeds == "%xgSUCCEEDS%xn"
        targets = Custom.parse_spell_targets(target_string, caster.combat)
        targets.each do |t|
          combat = caster.combat
          target = FS3Combat.find_named_thing(t, caster)
          target_combat = combat.find_combatant(t)
          return t('custom.not_ko', :target => self.target.name) if !target_combat.is_ko
          target_combat.update(is_ko: false)
          FS3Combat.emit_to_combat caster_combat.combat, t('custom.cast_res', :name => caster_combat.name, :spell => spell, :succeeds => succeeds, :target => target_combat.name)
          FS3Combat.emit_to_combatant target_combat, t('custom.been_resed', :name => caster_combat.name)
        end
      else
        FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

    def self.cast_multi_roll_spell(caster, caster_combat, target_string, spell)
      succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
      client = Login.find_client(caster_combat)
      if succeeds == "%xgSUCCEEDS%xn"
        targets = Custom.parse_spell_targets(target_string, caster.combat)
        targets.each do |t|
          target = FS3Combat.find_named_thing(t, caster)
          FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell_on_target', :name => caster_combat.name, :spell => spell, :target => target.name, :succeeds => succeeds)
        end
      else
        FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
      end
    end

    def self.cast_multi_noncombat_roll_spell(caster, target_string, spell)
      school = Global.read_config("spells", spell, "school")
      client = Login.find_client(caster)
      targets = Custom.parse_spell_targets(target_string, caster.combat)
      Rooms.emit_to_room(caster.room, targets)
      targets.each do |t|
        Rooms.emit_to_room(caster.room, t('custom.casts_noncombat_spell_with_target', :name => caster.name, :target => t.name, :spell => spell))
        die_result = FS3Skills.parse_and_roll(caster, school)
          success_level = FS3Skills.get_success_level(die_result)
          success_title = FS3Skills.get_success_title(success_level)
          message = t('fs3skills.simple_roll_result',
            :name => caster.name,
            :roll => school,
            :dice => FS3Skills.print_dice(die_result),
            :success => success_title
          )
          FS3Skills.emit_results message, client, caster.room, false
        end
    end


  end
end
