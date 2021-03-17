module AresMUSH
  module Magic

    def self.shields
      Global.read_config("spells").select { |spell| Global.read_config("spells", spell, "shields_against")}.map {|name, data| name}
    end

    def self.shield_types
      Global.read_config("spells").select { |spell| Global.read_config("spells", spell, "shields_against")}.map {|name, data| data['shields_against']}.uniq
    end

    def self.find_shield_named(char, shield_name)
      shield_name = shield_name.titlecase
      char.magic_shields.select { |shield| shield.name == shield_name }.first
    end

    def self.find_best_shield(char, damage_type)
      shields = []
      exceptions = Global.read_config("magic", "shields_against_all_exceptions")
      if !exceptions.include?(damage_type)
        shields.concat char.magic_shields.select { |shield| shield.shields_against == "All" }
      end
      shields_against_type = char.magic_shields.select { |shield| shield.shields_against == damage_type}
      sheilds = shields.concat shields_against_type
      best_shield = shields.max_by { |s| s.strength}
      if best_shield
        return best_shield
      else
        return false
      end
    end

    def self.shield_newturn_countdown(combatant)
      shields = combatant.associated_model.magic_shields
      shields.each do |shield|
        if shield.rounds == 0
          FS3Combat.emit_to_combat combatant.combat, t('magic.shield_wore_off', :name => combatant.name, :shield => shield.name), nil, true
          shield.delete
        else
          shield.update(rounds: shield.rounds - 1)
        end
      end
    end

    def self.determine_margin_with_shield(target, combatant, weapon_or_spell, attack_roll, defense_roll)
      attacker_net_successes = attack_roll - defense_roll
      stopped_by_shield = Magic.stopped_by_shield?(target, combatant, combatant.weapon, attack_roll)
      puts "***********#{stopped_by_shield}"
      if stopped_by_shield
        if stopped_by_shield[:hit]
          puts "Did this hit? #{stopped_by_shield[:hit]}"
          is_stun = Global.read_config("spells", weapon_or_spell, "is_stun") || FS3Combat.weapon_stat(weapon_or_spell, "is_stun") || false
          puts "Is stun? #{is_stun}"
          if is_stun
            hit = Magic.stun_successful?(stopped_by_shield[:hit], attacker_net_successes)
            puts "STUN SUCCEEDS? #{hit} Input: sbs(#{stopped_by_shield[:hit]}) net success (#{attacker_net_successes})"
          else
            hit = stopped_by_shield[:hit]
          end
        elsif !stopped_by_shield[:hit]
          hit = false
        end
        return {
          hit: hit,
          message: stopped_by_shield[:msg],
          shield: stopped_by_shield[:shield],
          shield_held: stopped_by_shield[:shield_held]
        }
      end
      #There is no shield in effect
    end

    def self.stopped_by_shield?(target_char_or_combatant, char_or_combatant, weapon_or_spell, result)
      if (target_char_or_combatant.class == Combatant)
        target = target_char_or_combatant.associated_model
      else
        target = target_char_or_combatant
      end
      damage_type = Magic.magic_damage_type(weapon_or_spell)
      roll_name = FS3Combat.weapon_stat(weapon_or_spell, "skill") || Global.read_config("spells", weapon_or_spell, "school")
      shield = Magic.find_best_shield(target, damage_type)
      puts "All shields: #{target.magic_shields.to_a}"
      # puts "Best shield: #{shield.name} #{shield.strength}"
      if shield
        successes = result
        if (char_or_combatant.class == Combatant)
          caster_name = char_or_combatant.associated_model.name
          char_or_combatant.log "#{shield.name.upcase}: #{caster_name}'s #{roll_name} (#{successes} successes) vs #{target.name}'s #{shield.name} (strength #{shield.strength})."
        # elsif !char_or_combatant.class
        #   caster_name = char_or_combatant
        #   Global.logger.info "#{shield.name.upcase}: #{caster_name}'s #{roll_name} (#{successes} successes) vs #{target.name}'s #{shield.name} (strength #{shield.strength})."
        else
          caster_name = char_or_combatant.name
          Global.logger.info "#{shield.name.upcase}: #{caster_name}'s #{roll_name} (#{successes} successes) vs #{target.name}'s #{shield.name} (strength #{shield.strength})."
        end

        delta = shield.strength - successes
        case delta
        when 0..99
          winner = "shield"
        when -99..-1
          winner = "caster"
        end

        puts "Shield delta #{shield.strength} - #{successes} #{delta} WINNER IS #{winner}"
        if !Magic.is_spell?(weapon_or_spell)
          success_msg = t('magic.shield_held_against_attack', :name => caster_name, :weapon => weapon_or_spell, :mod => "", :shield => shield.name, :target => target.name)
        else
          success_msg = t('magic.shield_held', :name => caster_name, :spell => weapon_or_spell, :mod => "", :shield => shield.name, :target => target.name)
        end
        failed_msg = Magic.shield_failed_msgs(target, caster_name, weapon_or_spell)

        if winner == "shield"
          puts "WINNER IS SHIELD"
          return {
          msg: success_msg,
          shield: shield.name,
          shield_held: true,
          hit: false
          }
        else
          puts "WINNER IS CASTER"
          return {
          msg: failed_msg,
          shield: shield.name,
          shield_held: false,
          hit: true
          }
        end
      end
      #There is no shield protecting against the damage type.
    end

    def self.shield_failed_msgs(target, caster_name, weapon_or_spell)
      damage_type =  Magic.magic_damage_type(weapon_or_spell)
      shield = Magic.find_best_shield(target, damage_type)
      type_does_damage = Global.read_config("magic",  "type_does_damage", damage_type)
      is_stun = Global.read_config("spells", weapon_or_spell, "is_stun") || Global.read_config("spells", weapon_or_spell, "is_stun") || FS3Combat.weapon_stat(weapon_or_spell, "is_stun") || false
      puts "#{weapon_or_spell} IS STUN? #{is_stun}"
      if weapon_or_spell.include?("Shrapnel")
          t('magic.shield_failed_against_shrapnel', :name => caster_name, :weapon => weapon_or_spell, :mod => "", :shield => shield.name, :target => target.name)
      elsif !Magic.is_spell?(weapon_or_spell)
        t('magic.shield_failed_against_attack', :name => caster_name, :weapon => weapon_or_spell, :mod => "", :shield => shield.name, :target => target.name)
      elsif type_does_damage
        t('magic.shield_failed', :name => caster_name, :spell => weapon_or_spell, :mod => "", :shield => shield.name, :target => target.name)
      elsif is_stun
         t('magic.shield_failed_stun', :name => caster_name, :spell => weapon_or_spell, :shield=> shield.name, :mod => "", :target => target.name, :rounds => Global.read_config("spells", weapon_or_spell, "rounds"))
      else
        t('magic.no_damage_shield_failed', :name => caster_name, :spell => weapon_or_spell, :mod => "", :shield => shield.name, :target => target.name)
      end
    end

    def self.shield_mods(target, damage_type)
      shield = Magic.find_best_shield(target, damage_type)
      shield_mod = (-20 - (shield.strength * 5))
      target.log "#{shield.name} mod: #{shield_mod}"
      return shield_mod
    end



  end
end
