module AresMUSH
  module FS3Combat

    def self.roll_attack(combatant, target, mod = 0)
      ability = FS3Combat.weapon_stat(combatant.weapon, "skill")
      accuracy_mod = FS3Combat.weapon_stat(combatant.weapon, "accuracy")
      special_mod = combatant.attack_mod
      item_attack_mod  = Custom.item_attack_mod(combatant.associated_model)
      damage_mod = combatant.total_damage_mod
      stance_mod = combatant.attack_stance_mod
      stress_mod = combatant.stress
      aiming_mod = (combatant.is_aiming? && (combatant.aim_target == combatant.action.target)) ? 3 : 0
      luck_mod = (combatant.luck == "Attack") ? 3 : 0
      distraction_mod = combatant.distraction

      if (combatant.mount_type && !target.mount_type)
        mount_mod = FS3Combat.mount_stat(combatant.mount_type, "mod_vs_unmounted")
      elsif (!combatant.mount_type && target.mount_type)
        mount_mod = 0 - FS3Combat.mount_stat(target.mount_type, "mod_vs_unmounted")
      else
        mount_mod = 0
      end

      combatant.log "Attack roll for #{combatant.name} ability=#{ability} aiming=#{aiming_mod} mod=#{mod} accuracy=#{accuracy_mod} damage=#{damage_mod} stance=#{stance_mod} mount=#{mount_mod} luck=#{luck_mod} stress=#{stress_mod} special=#{special_mod} item_attack=#{item_attack_mod} distract=#{distraction_mod}"

      mod = mod.to_i + accuracy_mod.to_i + damage_mod.to_i + stance_mod.to_i + aiming_mod.to_i + luck_mod.to_i - stress_mod.to_i + special_mod.to_i + item_attack_mod.to_i - distraction_mod.to_i + mount_mod.to_i


      combatant.roll_ability(ability, mod)
    end

    def self.roll_defense(combatant, attacker_weapon)
      ability = FS3Combat.weapon_defense_skill(combatant, attacker_weapon)
      stance_mod = combatant.defense_stance_mod
      luck_mod = (combatant.luck == "Defense") ? 3 : 0
      damage_mod = combatant.total_damage_mod
      special_mod = combatant.defense_mod
      dodge_mod = FS3Combat.vehicle_dodge_mod(combatant)
      distraction_mod = combatant.distraction
      armor_mod = FS3Combat.armor_stat(combatant.armor, 'defense') || 0

      mod = stance_mod + luck_mod + damage_mod + special_mod + dodge_mod + armor_mod - distraction_mod

      combatant.log "Defense roll for #{combatant.name} ability=#{ability} stance=#{stance_mod} damage=#{damage_mod} luck=#{luck_mod} special=#{special_mod} armor=#{armor_mod} dodge=#{dodge_mod} distract=#{distraction_mod}"

      combatant.roll_ability(ability, mod)
    end

    def self.roll_strength(combatant)
      strength = Global.read_config("fs3combat", "strength_skill")
      combatant.roll_ability(strength)
    end

    # Attacker           |  Defender            |  Skill
    # -------------------|----------------------|----------------------------
    # Any weapon         |  In Vehicle          |  Vehicle piloting skill
    # Melee weapon       |  Melee weapon        |  Defender's weapon skill
    # Melee weapon       |  Other weapon        |  Default combatant type skill
    # Other weapon       |  Other weapon        |  Default combatant type skill
    def self.weapon_defense_skill(combatant, attacker_weapon)
      if (combatant.is_in_vehicle?)
        return FS3Combat.vehicle_stat(combatant.vehicle.vehicle_type, "pilot_skill")
      end

      attacker_weapon_type = FS3Combat.weapon_stat(attacker_weapon, "weapon_type").titlecase
      defender_weapon_type = FS3Combat.weapon_stat(combatant.weapon, "weapon_type").titlecase
      if (attacker_weapon_type == "Melee" && defender_weapon_type == "Melee")
        skill = FS3Combat.weapon_stat(combatant.weapon, "skill")
      else
        skill = FS3Combat.combatant_type_stat(combatant.combatant_type, "defense_skill") ||
                Global.read_config("fs3combat", "default_defense_skill")
      end
      skill
    end

    def self.hitloc_chart(combatant, crew_hit = false)
      vehicle = combatant.vehicle
      if (!crew_hit && vehicle)
        hitloc_type = vehicle.hitloc_type
      else
        hitloc_type = FS3Combat.combatant_type_stat(combatant.combatant_type, "hitloc")
      end
      FS3Combat.hitloc_chart_for_type(hitloc_type)
    end

    def self.hitloc_areas(combatant, crew_hit = false)
      FS3Combat.hitloc_chart(combatant, crew_hit)["areas"]
    end

    def self.has_hitloc?(combatant, hitloc, crew_hit = false)
      hitlocs = FS3Combat.hitloc_areas(combatant, crew_hit)
      hitlocs.keys.map { |h| h.titlecase }.include?(hitloc.titlecase)
    end

    def self.hitloc_severity(combatant, hitloc, crew_hit = false)
      hitloc_chart = FS3Combat.hitloc_chart(combatant, crew_hit)
      vital_areas = hitloc_chart["vital_areas"]
      crit_areas = hitloc_chart["critical_areas"]

      return "Vital" if vital_areas.map { |v| v.titlecase }.include?(hitloc.titlecase)
      return "Critical" if crit_areas.map { |c| c.titlecase }.include?(hitloc.titlecase)
      return "Normal"
    end

    def self.determine_hitloc(combatant, attacker_net_successes, called_shot = nil, crew_hit = nil)
      return called_shot if (called_shot && attacker_net_successes > 2)

      hitloc_chart = FS3Combat.hitloc_areas(combatant, crew_hit)

      if (called_shot)
        locations = hitloc_chart[called_shot]
      else
        locations = hitloc_chart[hitloc_chart.keys.first]
      end

      roll = rand(locations.count) + attacker_net_successes
      roll = [roll, locations.count - 1].min
      roll = [0, roll].max
      locations[roll]
    end

    def self.roll_initiative(combatant, ability)
      luck_mod = combatant.luck == "Initiative" ? 3 : 0
      action_mod = 0
      if (combatant.action_klass == "AresMUSH::FS3Combat::SuppressAction" ||
          combatant.action_klass == "AresMUSH::FS3Combat::DistractAction" ||
          combatant.action_klass == "AresMUSH::FS3Combat::SubdueAction")
          action_mod = 3
      end
      weapon_mod = FS3Combat.weapon_stat(combatant.weapon, "init_mod") || 0
      roll = combatant.roll_ability(ability, weapon_mod + action_mod + luck_mod + combatant.total_damage_mod)

      combatant.log "Initiative roll for #{combatant.name} ability=#{ability} action=#{action_mod} weapon=#{weapon_mod} luck=#{luck_mod} roll=#{roll}"

      roll
    end

    def self.check_ammo(combatant, bullets)
      return true if combatant.max_ammo == 0
      combatant.ammo >= bullets
    end

    def self.update_ammo(combatant, bullets)
      return nil if combatant.max_ammo == 0

      ammo = combatant.ammo - bullets
      combatant.update(ammo: ammo)

      if (ammo == 0)
        t('fs3combat.weapon_clicks_empty', :name => combatant.name)
      else
        nil
      end
    end

    def self.update_combatant(combat, combatant, enactor, team, stance,
      weapon, selected_weapon_specials, armor, selected_armor_specials, npc_level)

      if (team != combatant.team)
        combatant.update(team: team)
        FS3Combat.emit_to_combat combat, t('fs3combat.team_set', :name => combatant.name, :team => team ), FS3Combat.npcmaster_text(combatant.name, enactor)
      end

      if (stance != combatant.stance)
        combatant.update(stance: stance)
        FS3Combat.emit_to_combat combat, t('fs3combat.stance_changed', :name => combatant.name, :poss => combatant.poss_pronoun, :stance => stance), FS3Combat.npcmaster_text(combatant.name, enactor)
      end

      allowed_specials = FS3Combat.weapon_stat(weapon, "allowed_specials") || []
      weapon_specials = []
      selected_weapon_specials.each do |name|
        if (allowed_specials.include?(name))
          weapon_specials << name
        else
          return t('fs3combat.invalid_weapon_special', :special => name)
        end
      end

      if (combatant.weapon_name != weapon || combatant.weapon_specials != weapon_specials)
        FS3Combat.set_weapon(enactor, combatant, weapon, weapon_specials)
      end


      allowed_specials = FS3Combat.armor_stat(armor, "allowed_specials") || []
      armor_specials = []
      selected_armor_specials.each do |name|
        if (allowed_specials.include?(name))
          armor_specials << name
        else
          return t('fs3combat.invalid_armor_special', :special => name)
        end
      end

      if (armor != combatant.armor_name || combatant.armor_specials != armor_specials)
        FS3Combat.set_armor(enactor, combatant, armor, armor_specials)
      end

      if (combatant.is_npc? && combatant.npc.level != npc_level)
        combatant.npc.update(level: npc_level)
      end

      return nil
    end
  end
end
