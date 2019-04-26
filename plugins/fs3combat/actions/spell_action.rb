module AresMUSH
  module FS3Combat
    class SpellAction < CombatAction
      attr_accessor  :spell, :target, :names

      def prepare
        if (self.action_args =~ /\//)
          self.names = self.action_args.before("/")
          self.spell = self.action_args.after("/")
        else
          self.names = self.name
          self.spell = self.action_args

        end

        error = self.parse_targets(self.names)
        return error if error

        return t('fs3combat.only_one_target') if (self.targets.count > 1)
      end

      def print_action
        msg = t('custom.spell_target_action_msg_long', :name => self.name, :spell => self.spell, :target => print_target_names)
        msg
      end

      def print_action_short
        t('custom.spell_target_action_msg_short', :targets => print_target_names)
      end

      def resolve
        succeeds = Custom.roll_combat_spell_success(self.combatant, self.spell)
        messages = []
        if succeeds == "%xgSUCCEEDS%xn"
          weapon = Global.read_config("spells", self.spell, "weapon")
          weapon_specials_str = Global.read_config("spells", self.spell, "weapon_specials")
          armor = Global.read_config("spells", self.spell, "armor")
          armor_specials_str = Global.read_config("spells", self.spell, "armor_specials")
          heal_points = Global.read_config("spells", self.spell, "heal_points")
          is_revive = Global.read_config("spells", self.spell, "is_revive")
          is_res = Global.read_config("spells", self.spell, "is_res")
          damage_inflicted = Global.read_config("spells", self.spell, "damage_inflicted")
          damage_desc = Global.read_config("spells", spell, "damage_desc")
          lethal_mod = Global.read_config("spells", self.spell, "lethal_mod")
          attack_mod = Global.read_config("spells", self.spell, "attack_mod")
          defense_mod = Global.read_config("spells", self.spell, "defense_mod")
          spell_mod = Global.read_config("spells", self.spell, "spell_mod")
          stance = Global.read_config("spells", self.spell, "stance")
          target_optional = Global.read_config("spells", self.spell, "target_optional")
          roll = Global.read_config("spells", self.spell, "roll")
          effect = Global.read_config("spells", self.spell, "effect")




          targets.each do |target|
            #Psionic attacks against mind shield
            if (effect == "Psionic" && target.mind_shield > 0 && Custom.roll_mind_shield(target, combatant) == "shield")

              messages.concat [t('custom.mind_shield_held', :name => self.name, :spell => self.spell, :target => print_target_names)]

            else

              #Psionic Protection
              if self.spell == "Mind Shield"
                shield_strength = combatant.roll_ability("Spirit")
                target.update(mind_shield: shield_strength)
                rounds = Global.read_config("spells", self.spell, "rounds")
                
                target.update(mind_shield_counter: rounds)
                Global.logger.debug "SHIELD STRENGTH: #{shield_strength}"

                Global.logger.debug "MIND SHIELD: #{target.mind_shield}"

                messages.concat [t('custom.cast_mindshield', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target =>  print_target_names)]
              end



              #Healing
              if heal_points
                wound = FS3Combat.worst_treatable_wound(target.associated_model)

                if (wound)
                  if target.death_count > 0
                    messages.concat [t('custom.cast_ko_heal', :name => self.name, :spell => spell, :succeeds => succeeds, :target => target.name, :points => heal_points)]
                  else
                    messages.concat [t('custom.cast_heal', :name => self.name, :spell => spell, :succeeds => succeeds, :target => target.name, :points => heal_points)]
                  end
                else
                   messages.concat [t('custom.cast_heal_no_effect', :name => self.name, :spell => spell, :succeeds => succeeds, :target => print_target_names)]
                end
                target.update(death_count: 0  )
              end

              #Equip Weapon
              if weapon && weapon != "Spell"
                FS3Combat.set_weapon(combatant, target, weapon)
                if armor

                else
                  messages.concat [t('custom.casts_spell', :name => self.name, :spell => self.spell, :succeeds => succeeds)]
                end
              end

              #Equip Weapon Specials
              if weapon_specials_str
                Custom.spell_weapon_effects(target, self.spell)

                weapon = target.weapon.before("+")

                FS3Combat.set_weapon(nil, target, weapon, [weapon_specials_str])

                if heal_points

                elsif lethal_mod || defense_mod || attack_mod || spell_mod

                else
                  messages.concat [t('custom.casts_spell', :name => self.name, :spell => self.spell, :succeeds => succeeds)]
                end
              end

              #Equip Armor
              if armor && armor != "Spell"
                FS3Combat.set_armor(combatant, target, armor)
                messages.concat [t('custom.casts_spell', :name => self.name, :spell => self.spell, :succeeds => succeeds)]
              end

              #Equip Armor Specials
              if armor_specials_str
                armor_specials = armor_specials_str ? armor_specials_str.split('+') : nil
                FS3Combat.set_armor(combatant, target, target.armor, armor_specials)
                messages.concat [t('custom.casts_spell', :name => self.name, :spell => self.spell, :succeeds => succeeds)]
              end



              #Reviving
              if is_revive
                target.update(is_ko: false)
                messages.concat [t('custom.cast_res', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target => print_target_names)]
                FS3Combat.emit_to_combatant target, t('custom.been_resed', :name => self.name)
              end

              #Ressurrection
              if is_res
                Custom.undead(target.associated_model)
                messages.concat [t('custom.cast_res', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target => print_target_names)]
                FS3Combat.emit_to_combatant target, t('custom.been_resed', :name => self.name)
              end


              #Inflict Damage
              if damage_inflicted
                FS3Combat.inflict_damage(target.associated_model, damage_inflicted, damage_desc)
                target.update(freshly_damaged: true)
                messages.concat [t('custom.cast_damage', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target => print_target_names, :damage_desc => spell.downcase)]
              end

              #Apply Mods
              if lethal_mod
                rounds = Global.read_config("spells", self.spell, "rounds")
                target.update(lethal_mod_counter: rounds)
                target.update(damage_lethality_mod: lethal_mod)
                messages.concat [t('custom.cast_mod', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target =>  print_target_names, :mod => lethal_mod, :type => "lethality")]
              end

              if attack_mod
                rounds = Global.read_config("spells", self.spell, "rounds")
                target.update(attack_mod_counter: rounds)
                target.update(attack_mod: attack_mod)
                messages.concat [t('custom.cast_mod', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target =>  print_target_names, :mod => attack_mod, :type => "attack")]
              end

              if defense_mod
                rounds = Global.read_config("spells", self.spell, "rounds")
                target.update(defense_mod_counter: rounds)
                target.update(defense_mod: defense_mod)
                messages.concat [t('custom.cast_mod', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target =>  print_target_names, :mod => defense_mod, :type => "defense")]
              end

              if spell_mod
                rounds = Global.read_config("spells", self.spell, "rounds")
                target.update(spell_mod_counter: rounds)
                target.update(spell_mod: spell_mod)
                messages.concat [t('custom.cast_mod', :name => self.name, :spell => self.spell, :succeeds => succeeds, :target =>  print_target_names, :mod => spell_mod, :type => "spell")]
              end

              #Change Stance
              if stance
                target.update(stance: stance)
                messages.concat [t('custom.cast_stance', :name => self.name, :target => print_target_names, :spell => self.spell, :succeeds => succeeds, :stance => stance)]
              end

              #Roll
              if roll
                # succeeds = Custom.roll_combat_spell_success(self.combatant, self.spell)

                if target
                  if effect == "Psionic"
                    messages.concat [t('custom.mind_shield_failed', :name => self.name, :spell => self.spell, :target => print_target_names, :succeeds => succeeds)]
                  else
                    messages.concat [t('custom.spell_target_resolution_msg', :name => self.name, :spell => self.spell, :target => print_target_names, :succeeds => succeeds)]
                  end
                else
                  messages.concat [t('custom.spell_resolution_msg', :name => self.name, :spell => self.spell, :succeeds => succeeds)]
                end
              end
            #End Psionic Protection Rolls
            end
          #End if spell succeeds
          end
        elsif self.spell == "Phoenix's Healing Flames"
          messages.concat [t('custom.cast_phoenix_heal', :name => self.name, :spell => self.spell, :succeeds => "%xgSUCCEEDS%xn")]
        else
          #Spell fails
          messages.concat [t('custom.spell_target_resolution_msg', :name => self.name, :spell => spell, :target => print_target_names, :succeeds => succeeds)]
        end
        level = Global.read_config("spells", self.spell, "level")
        if level == 8
          messages.concat [t('custom.level_eight_fatigue', :name => self.name)]
        end
        messages
      end
    end
  end
end
