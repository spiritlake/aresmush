module AresMUSH
  module Custom

    def self.cast_inflict_damage(caster, target, spell)
      succeeds = Custom.roll_combat_spell_success(caster, spell)
      damage_desc = Global.read_config("spells", spell, "damage_desc")
      damage_inflicted = Global.read_config("spells", spell, "damage_inflicted")
      return t('custom.cant_heal_dead') if (target.dead)
      if succeeds == "%xgSUCCEEDS%xn"
        FS3Combat.inflict_damage(target, damage_inflicted, damage_desc)
        FS3Combat.emit_to_combat caster.combat, t('custom.cast_damage', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name, :damage_desc => spell.downcase)
      else
        FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

    def self.cast_heal(caster, target, spell)
      succeeds = Custom.roll_combat_spell_success(caster, spell)
      if succeeds == "%xgSUCCEEDS%xn"
        wound = FS3Combat.worst_treatable_wound(target)
        heal_points = Global.read_config("spells", spell, "heal_points")
        if (wound)
          FS3Combat.heal(wound, heal_points)
          FS3Combat.emit_to_combat caster.combat, t('custom.cast_heal', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name, :points => heal_points)
        else
          FS3Combat.emit_to_combat caster.combat, t('custom.cast_heal_no_effect', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name)
        end
      else
        FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

    def self.cast_non_combat_heal(caster, target, spell)
      succeeds = Custom.roll_noncombat_spell_success(caster, spell)
      client = Login.find_client(caster)
      if succeeds == "%xgSUCCEEDS%xn"
        wound = FS3Combat.worst_treatable_wound(target)
        heal_points = Global.read_config("spells", spell, "heal_points")
        if (wound)
          FS3Combat.heal(wound, heal_points)
          client.emit t('custom.cast_heal', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name, :points => heal_points)
        else
          client.emit t('custom.cast_heal_no_effect', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name)
        end
      else
        client.emit t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

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

    # def self.cast_revive(caster, target_combat, spell)
    #   succeeds = Custom.roll_combat_spell_success(caster, spell)
    #   if succeeds == "%xgSUCCEEDS%xn"
    #     target_combat.update(is_ko: false)
    #     FS3Combat.emit_to_combat caster.combat, t('custom.cast_revive', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target_combat.name)
    #     FS3Combat.emit_to_combatant target_combat, t('custom.been_revived', :name => caster.name)
    #   else
    #     FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
    #   end
    # end

    def self.cast_revive(caster, target, target_combat, spell)
      succeeds = Custom.roll_combat_spell_success(caster, spell)
      if succeeds == "%xgSUCCEEDS%xn"
        Custom.undead(target)
        FS3Combat.emit_to_combat caster.combat, t('custom.cast_res', :name => caster.name, :spell => spell, :succeeds => succeeds, :target => target.name)
        FS3Combat.emit_to_combatant target_combat, t('custom.been_resed', :name => caster.name)
      else
        FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

    def self.cast_lethal_mod(caster, target_combat, spell)
      succeeds = "%xgSUCCEEDS%xn"
      lethal_mod = Global.read_config("spells", spell, "lethal_mod")
      current_mod = target_combat.damage_lethality_mod
      new_mod = current_mod + lethal_mod
      target_combat.update(damage_lethality_mod: new_mod)
      FS3Combat.emit_to_combat caster.combat, t('cast_mod', :name => caster.name, :spell => spell, :succeeds => succeeds, :target =>  target_combat.name, :mod => lethal_mod, :type => "lethality", :total_mod => target_combat.damage_lethality_mod)
    end

    def self.cast_defense_mod(caster,  target_combat, spell)
      succeeds = "%xgSUCCEEDS%xn"
      defense_mod = Global.read_config("spells", spell, "defense_mod")
      current_mod =  target_combat.defense_mod
      new_mod = current_mod + defense_mod
      target_combat.update(defense_mod: new_mod)
      FS3Combat.emit_to_combat caster.combat, t('custom.cast_mod', :name => caster.name, :target => target_combat.name, :spell => spell, :succeeds => succeeds, :mod => defense_mod, :type => "defense", :total_mod => target_combat.defense_mod)
    end

    def self.cast_attack_mod(caster, target_combat, spell)
      succeeds = "%xgSUCCEEDS%xn"
      attack_mod = Global.read_config("spells", spell, "attack_mod")
      current_mod = target_combat.attack_mod
      new_mod = current_mod + attack_mod
      target_combat.update(attack_mod: new_mod)
      FS3Combat.emit_to_combat caster.combat, t('custom.cast_mod', :name => caster.name, :target => target_combat.name, :spell => spell, :succeeds => succeeds, :mod => attack_mod, :type => "attack", :total_mod => target_combat.attack_mod)
    end

    def self.cast_spell_mod(caster, target_combat, spell)
      succeeds = "%xgSUCCEEDS%xn"
      spell_mod = Global.read_config("spells", spell, "spell_mod")
      current_mod = target_combat.spell_mod.to_i
      new_mod = current_mod + spell_mod
      target_combat.update(spell_mod: new_mod)
      FS3Combat.emit_to_combat caster.combat, t('custom.cast_mod', :name => caster.name, :target => target_combat.name, :spell => spell, :succeeds => succeeds, :mod => spell_mod, :type => "spell", :total_mod => target_combat.spell_mod)
    end

    def self.cast_stance(caster, target_combat, spell)
      succeeds = Custom.roll_combat_spell_success(caster, spell)
      if succeeds == "%xgSUCCEEDS%xn"
        stance = Global.read_config("spells", spell, "stance")
        target_combat.update(stance: stance)
        FS3Combat.emit_to_combat caster.combat, t('custom.cast_stance', :name => caster.name, :target => target_combat.name, :spell => spell, :succeeds => succeeds, :stance => stance)
      else
        FS3Combat.emit_to_combat caster.combat, t('custom.casts_spell', :name => caster.name, :spell => spell, :succeeds => succeeds)
      end
    end

    def self.cast_equip_weapon_with_target(enactor, caster_combat, target_combat, spell)
      succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
      weapon = Global.read_config("spells", spell, "weapon")
      client = Login.find_client(caster_combat)
      armor = Global.read_config("spells", spell, "armor")
      if succeeds == "%xgSUCCEEDS%xn"
        if armor

        else
          FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
        end

        FS3Combat.set_weapon(enactor, target_combat, weapon)
      else
        FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
      end
      FS3Combat.set_action(client, caster_combat, caster_combat.combat, caster_combat, FS3Combat::SpellAction, "")
    end

    def self.cast_equip_weapon_specials(enactor, caster_combat, spell)
      weapon_specials_str = Global.read_config("spells", spell, "weapon_specials")
      weapon_specials = weapon_specials_str ? weapon_specials_str.split('+') : nil
      succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
      client = Login.find_client(caster_combat)
      if succeeds == "%xgSUCCEEDS%xn"
        FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
        FS3Combat.set_weapon(enactor, caster_combat, caster_combat.weapon, weapon_specials)
      else
        FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
      end
      FS3Combat.set_action(client, caster_combat, caster_combat.combat, caster_combat, FS3Combat::SpellAction, "")
    end

    def self.cast_equip_armor_specials(enactor, caster_combat, spell)
      succeeds = Custom.roll_combat_spell_success(caster_combat, spell)
      armor_specials_str = Global.read_config("spells", spell, "armor_specials")
      armor_specials = armor_specials_str ? armor_specials_str.split('+') : nil
      client = Login.find_client(caster_combat)
      if succeeds == "%xgSUCCEEDS%xn"
        FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
        FS3Combat.set_armor(enactor, caster_combat, caster_combat.armor, armor_specials)
      else
        FS3Combat.emit_to_combat caster_combat.combat, t('custom.casts_spell', :name => caster_combat.name, :spell => spell, :succeeds => succeeds)
      end
      FS3Combat.set_action(client, caster_combat, caster_combat.combat, caster_combat, FS3Combat::SpellAction, "")
    end

  end
end
