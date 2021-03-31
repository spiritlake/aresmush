module AresMUSH
  module Magic


    def self.cast_noncombat_spell(caster_name, targets, spell, mod = nil, result = nil, using_potion = false)
      success = "%xgSUCCEEDS%xn"
      is_shield = Global.read_config("spells", spell, "is_shield")
      rounds = Global.read_config("spells", spell, "rounds")
      heal_points = Global.read_config("spells", spell, "heal_points")
      caster = Character.named(caster_name)

      names = []
      messages = []
      targets.each do |target|
        stopped_by_shield = Magic.stopped_by_shield?(target, caster, spell, result)
        if stopped_by_shield && caster != target && !using_potion
          message = stopped_by_shield[:msg]
          messages.concat [message]
        else
          names.concat [target.name]
          if is_shield
            Magic.cast_shield(caster, target, spell, rounds, result)
          end

          if heal_points
            Magic.cast_heal(caster, target, spell, heal_points)
          end
        end
      end

      if using_potion
        message = [Magic.get_potion_message(caster, names[0], spell)]
        messages.concat message
      else
        if (!names.empty? && names.all?(caster_name))
          if is_shield
            type = Global.read_config("spells", spell, "shields_against")
            message = [t('magic.cast_shield_no_target', :name => caster.name, :spell => spell, :mod => "", :succeeds => success, :type => type)]
            messages.concat message
          end
          if !heal_points && !is_shield
            message = [t('magic.casts_spell', :name => caster_name, :spell => spell, :mod => mod, :succeeds => success)]
            messages.concat message
          end
        elsif !names.empty?
          print_names = names.join(", ")
          if is_shield
            type = Global.read_config("spells", spell, "shields_against")
            message = [t('magic.cast_shield', :name => caster.name, :spell => spell, :mod => "", :succeeds => success, :target =>  print_names, :type => type)]
            messages.concat message
          end
          if heal_points
            message = [t('magic.cast_heal', :name => caster.name, :spell => spell, :mod => "", :succeeds => success, :target => print_names, :points => heal_points)]
            messages.concat message
          end
          if !heal_points && !is_shield
            message = [t('magic.casts_spell_on_target', :name => caster_name, :target => print_names, :spell => spell, :mod => mod, :succeeds => success)]
            messages.concat message
          end
        end
      end

      # if Global.read_config("spells", spell, "fs3_attack") || Global.read_config("spells", spell, "is_stun")
      #   messages.concat ["%xrAttack and stun spells have no real damage effects outside of combat. Start a combat if you want damage to persist.%xn"]
      # end

      return messages
    end

    def self.cast_shield(char_or_combatant, target_char_or_combatant, spell, rounds, result)
      if (char_or_combatant.class == Combatant)
        caster = char_or_combatant.associated_model
        target = target_char_or_combatant.associated_model
      else
        caster = char_or_combatant
        target = target_char_or_combatant
      end
      shield = Magic.find_shield_named(target, spell)

      if shield
        shield.update(strength: result)
        shield.update(rounds: rounds)
      else
        shield = {
          name: spell,
          strength: result,
          rounds: rounds,
          character: target,
          npc: target
          }
        MagicShields.create(shield)
      end
      puts "***************ALL SHIELDS #{target.magic_shields.to_a}***************"

      shield = Magic.find_shield_named(target, spell)
      type = Global.read_config("spells", spell, "shields_against")
      # type = "All" ? type = "all" : type = type
      if (char_or_combatant.class == Combatant)
        char_or_combatant.log "Setting #{target.name}'s #{spell.upcase} to #{shield.strength}"
      else
        Global.logger.info "Setting #{target.name}'s #{spell.upcase} to #{shield.strength}"
      end
      message = [t('magic.cast_shield', :name => caster.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target =>  target.name, :type => type)]
      return message
    end

    def self.cast_heal(char_or_combatant, target, spell, heal_points)
      if (char_or_combatant.class == Combatant)
        caster = char_or_combatant.associated_model
        target = target.associated_model
      else
        caster = char_or_combatant
        target = target
      end
      wound = FS3Combat.worst_treatable_wound(target)
      if wound.blank?
        message = [t('magic.no_healable_wounds', :target => target.name)]
      elsif target.class == Combatant && target.death_count > 0
        message = [t('magic.cast_ko_heal', :name => char_or_combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target => target.name, :points => heal_points)]
        target.update(death_count: 0 )
        FS3Combat.heal(wound, heal_points)
      else
        message = [t('magic.cast_heal', :name => char_or_combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target => target.name, :points => heal_points)]
        FS3Combat.heal(wound, heal_points)
      end
      return message
    end

    def self.cast_weapon(combatant, target, spell, weapon)
      armor = Global.read_config("spells", spell, "armor")
      Magic.set_magic_weapon(combatant, target, weapon)
      if armor
        message = []
      else
        message = [t('magic.casts_spell', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn")]
      end
      return message
    end

    def self.cast_weapon_specials(combatant, target, spell, weapon_specials_str)
      heal_points = Global.read_config("spells", spell, "heal_points")
      lethal_mod = Global.read_config("spells", spell, "lethal_mod")
      defense_mod = Global.read_config("spells", spell, "defense_mod")
      spell_mod = Global.read_config("spells", spell, "spell_mod")
      attack_mod = Global.read_config("spells", spell, "attack_mod")
      wound = FS3Combat.worst_treatable_wound(target.associated_model)
      weapon = target.weapon.before("+")
      Magic.set_magic_weapon_effects(target, spell)
      Magic.set_magic_weapon(enactor = nil, target, weapon, [weapon_specials_str])
      if (heal_points && wound)
        message = []
      elsif lethal_mod || defense_mod || attack_mod || spell_mod
        message = []
      elsif combatant != target
        message = [t('magic.casts_spell_on_target', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn")]
      else
        message = [t('magic.casts_spell', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn")]
      end
    end

    def self.cast_armor(combatant, target, spell, armor)
      Magic.set_magic_armor(combatant, target, armor)
      if combatant != target
        message = [t('magic.casts_spell_on_target', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn")]
      else
        message = [t('magic.casts_spell', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn")]
      end
      return message
    end

    def self.cast_armor_specials(combatant, target, spell, armor_specials_str)
      armor_specials = armor_specials_str ? armor_specials_str.split('+') : nil
      Magic.set_magic_armor(combatant, target, target.armor, armor_specials)
      message = [t('magic.casts_spell', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn")]
      return message
    end

    def self.cast_revive(combatant, target, spell)
      target.update(is_ko: false)
      FS3Combat.emit_to_combatant target, t('magic.been_revive', :name => combatant.name)
      message = [t('magic.cast_revive', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target => target.name)]
      return message
    end

    def self.cast_auto_revive(combatant, target, spell)
      target.update(death_count: 0)
      target.update(is_ko: false)
      target.log "Auto-revive spell setting #{target.name}'s KO to #{target.is_ko}."
      Magic.heal_all_unhealed_damage(target.associated_model)
      FS3Combat.emit_to_combatant target, t('magic.been_revived', :name => combatant.name)
      if target != combatant
        message = [t('magic.cast_auto_revive_target', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target => target.name)]
      else
        message = [t('magic.cast_auto_revive', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn")]
      end
      return message
    end

    def self.cast_resurrection(combatant, target, spell)
      Custom.undead(target.associated_model)
      message = [t('magic.cast_res', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target => target.name)]
      FS3Combat.emit_to_combatant target, t('magic.been_resed', :name => combatant.name)
      return message
    end

    def self.cast_inflict_damage(combatant, target, spell, damage_inflicted, damage_desc)
      FS3Combat.inflict_damage(target.associated_model, damage_inflicted, damage_desc)
      target.update(freshly_damaged: true)
      damaged_by = target.damaged_by
      damaged_by << combatant.name
      target.update(damaged_by: damaged_by.uniq)
      message = [t('magic.cast_damage', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target => target.name, :damage_desc => spell.downcase)]
      return message
    end

    def self.cast_mod(combatant, target, spell, damage_type, rounds, result, attack_mod = nil, defense_mod = nil, init_mod = nil, lethal_mod = nil, spell_mod = nil)
      stopped_by_shield = Magic.stopped_by_shield?(target, combatant, spell, result)
      if stopped_by_shield && combatant != target
        if stopped_by_shield[:hit]
          mod_msg = Magic.update_spell_mods(target, rounds, attack_mod, defense_mod, init_mod, lethal_mod, spell_mod)
          message = [t('magic.mod_shield_failed', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target =>  target.name, :mod_msg => mod_msg, :shield => stopped_by_shield[:shield])]
        else
          message = [stopped_by_shield[:msg]]
        end
      else
        mod_msg = Magic.update_spell_mods(target, rounds, attack_mod, defense_mod, init_mod, lethal_mod, spell_mod)
        message = [t('magic.cast_mod', :name => combatant.name, :spell => spell, :mod => "", :succeeds => "%xgSUCCEEDS%xn", :target =>  target.name, :mod_msg => mod_msg)]
      end
      return message
    end

    def self.update_spell_mods (target, rounds, attack_mod = nil, defense_mod = nil, init_mod = nil, lethal_mod = nil, spell_mod = nil)
      mod_msg = []
      if attack_mod
        target.update(magic_attack_mod: attack_mod)
        target.update(magic_attack_mod_counter: rounds)
        mod_msg.concat ["#{attack_mod} attack"]
      end
      if defense_mod
        target.update(magic_defense_mod: defense_mod)
        target.update(magic_defense_mod_counter: rounds)
        mod_msg.concat ["#{defense_mod} defense"]
      end
      if init_mod
        target.update(magic_init_mod: init_mod)
        target.update(magic_init_mod_counter: rounds)
        mod_msg.concat ["#{init_mod} initative"]
      end
      if lethal_mod
        target.update(magic_lethal_mod: lethal_mod)
        target.update(magic_lethal_mod_counter: rounds)
        mod_msg.concat ["#{lethal_mod} lethality"]
      end
      if spell_mod
        target.update(spell_mod: spell_mod)
        target.update(spell_mod_counter: rounds)
        mod_msg.concat ["#{spell_mod} spell casting"]
      end
      mod_msg = mod_msg.join(", ")
      target.combat.log "SETTING SPELL MODS (mod/rounds): Attack:#{target.magic_attack_mod}/#{target.magic_attack_mod_counter} Defense:#{target.magic_defense_mod}/#{target.magic_defense_mod_counter} Init:#{target.magic_init_mod}/#{target.magic_init_mod_counter} Lethal:#{target.magic_lethal_mod}/#{target.magic_lethal_mod_counter} Spell:#{target.spell_mod}/#{target.spell_mod_counter}"
      return mod_msg
    end

    def self.cast_stance(combatant, target, spell, damage_type, rounds, stance, result)
      stopped_by_shield = Magic.stopped_by_shield?(target, combatant, spell, result)
      if stopped_by_shield&& combatant != target
        if stopped_by_shield[:hit]
          target.update(stance: stance.titlecase)
          target.update(stance_counter: rounds)
          target.update(stance_spell: spell)
        end
        message = [stopped_by_shield[:msg]]
      else
        target.update(stance: stance.titlecase)
        target.update(stance_counter: rounds)
        target.update(stance_spell: spell)
        message = [t('magic.spell_target_resolution_msg', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn")]
      end
      return message
    end

    def self.cast_combat_roll(combatant, target, spell, damage_type, result = nil)
      if combatant != target
        stopped_by_shield = Magic.stopped_by_shield?(target, combatant, spell, result)
        if stopped_by_shield
          message = [stopped_by_shield[:msg]]
        else
          message = [t('magic.spell_target_resolution_msg', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn")]
        end
      else
        message = [t('magic.spell_target_resolution_msg', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn")]
      end
      return message
    end

    def self.cast_stun(combatant, target, spell, rounds, result)
      if target == combatant
        message = t('magic.dont_target_self')
        return message
      end
      margin = FS3Combat.determine_attack_margin(combatant, target)
      stopped_by_shield = margin[:stopped_by_shield] || []
      puts "++++ #{margin}"
      puts "++++ #{stopped_by_shield}"
      ###NEEDS TO GRAB THE SHIELD NAME ARG
      if (margin[:hit])
        puts "Stun hits"
        target.update(subdued_by: combatant)
        target.update(magic_stun: true)
        target.update(magic_stun_counter: rounds.to_i)
        target.update(magic_stun_spell: spell)
        target.update(action_klass: nil)
        target.update(action_args: nil)
        if !stopped_by_shield.empty?
          #Needs to grab its own message instead of using stopped_by_shield[:message] so it can grab the spell name.
          message = [Magic.shield_failed_msgs(target, combatant.name, spell)]
        else
          message = [t('magic.cast_stun', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn", :rounds => rounds)]
        end
      else
        if (!stopped_by_shield.empty? && stopped_by_shield[:shield_held])
          puts "^^^^^^There is a shield, and it held (hit = false)"
          #Needs to define own message instead of using stopped_by_shield[:message] so it can grab the spell name instead of the weapon name.
          message =[t('magic.shield_held', :name => combatant.name, :spell => spell, :mod => "", :shield => stopped_by_shield[:shield], :target => target.name)]
        elsif !stopped_by_shield.empty?
          puts "^^^^^^There is a shield and hit != false"
          message = [t('magic.shield_failed_stun_resisted', :name => combatant.name, :spell => spell, :shield=> stopped_by_shield[:shield], :mod => "", :target => target.name)]
        else
          puts "^^^^^^There is no shield"
          message = [t('magic.cast_stun_resisted', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xgSUCCEEDS%xn")]
        end
      end
      return message
    end

    def self.cast_explosion(combatant, target, spell, result)
      messages = []
      margin = FS3Combat.determine_attack_margin(combatant, target, result = result, spell)
      if (margin[:hit])
        attacker_net_successes = margin[:attacker_net_successes]
        messages.concat FS3Combat.resolve_attack(combatant, combatant.name, target, combatant.weapon, attacker_net_successes)
        max_shrapnel = [ 5, attacker_net_successes + 2 ].min
      else
        messages << margin[:message]
        max_shrapnel = 2
      end
      if (FS3Combat.weapon_stat(combatant.weapon, "has_shrapnel"))
        #If there's shrapnel, figure out how much by choosing a random number from max_shrapnel
        shrapnel = rand(max_shrapnel).round()
        damage_type =  Magic.magic_damage_type(spell)
        shrapnel.times.each do |s|
          margin = FS3Combat.determine_attack_margin(combatant, target, result = result, spell)
          attacker_net_successes = margin[:attacker_net_successes]
          if damage_type
            messages.concat FS3Combat.resolve_attack(nil, combatant.name, target, "#{damage_type} Shrapnel", attacker_net_successes)
          else
            messages.concat FS3Combat.resolve_attack(nil, combatant.name, target, "Shrapnel", attacker_net_successes)
          end

        end
      end
      return messages
    end

    def self.cast_suppress(combatant, target, spell, result)
      composure = Global.read_config("fs3combat", "composure_skill")
      attack_roll = result
      defense_roll = target.roll_ability(composure)
      margin = attack_roll - defense_roll

      combatant.log "#{combatant.name} suppressing #{target.name} with #{spell}. atk=#{attack_roll} def=#{defense_roll} margin=#{margin}"
      if (margin >= 0)
        target.add_stress(margin + 2)
        message = [t('fs3combat.suppress_successful_msg', :name => combatant.name, :target => target.name, :weapon => "%xB#{combatant.weapon}%xn")]
      else
        message = [t('magic.casts_spell_on_target', :name => combatant.name, :spell => spell, :mod => "", :target => target.name, :succeeds => "%xrFAILS%xn")]
      end
      return message
    end

    def self.cast_attack_target(combatant, target, called_shot = nil, result)
        return [ t('fs3combat.has_no_target', :name => combatant.name) ] if !target
        margin = FS3Combat.determine_attack_margin(combatant, target, result = result, combatant.weapon)

        # Update recoil after determining the attack success but before returning out for a miss
        recoil = FS3Combat.weapon_stat(combatant.weapon, "recoil")
        combatant.update(recoil: combatant.recoil + recoil)

        return [margin[:message]] if !margin[:hit]

        weapon = combatant.weapon
        attacker_net_successes = margin[:attacker_net_successes]

        FS3Combat.resolve_attack(combatant, combatant.name, target, weapon, attacker_net_successes, called_shot)
      end

  end
end