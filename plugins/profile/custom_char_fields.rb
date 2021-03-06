module AresMUSH
  module Profile
    class CustomCharFields

      # Gets custom fields for display in a character profile.
      #
      # @param [Character] char - The character being requested.
      # @param [Character] viewer - The character viewing the profile. May be nil if someone is viewing
      #    the profile without being logged in.
      #
      # @return [Hash] - A hash containing custom fields and values.
      #    Ansi or markdown text strings must be formatted for display.
      # @example
      #    return { goals: Website.format_markdown_for_html(char.goals) }
      def self.get_fields_for_viewing(char, viewer)
        spells = Magic.spell_list_all_data(char.spells_learned)
        return {
          comps: Compliments.get_comps(char),
          spells: spells,
          major_spells: Magic.major_school_spells(char, spells),
          minor_spells: Magic.minor_school_spells(char, spells),
          other_spells: Magic.other_spells(char, spells),
          major_school: char.group("Major School"),
          minor_school: char.group("Minor School"),
          magic_items: Magic.get_magic_items(char),
          potions: Magic.get_potions(char),
          potions_creating: Magic.get_potions_creating(char),
          lore_hook_name: char.lore_hook_name,
          lore_hook_desc: char.lore_hook_desc,
          lore_hook_item: Lorehooks.lore_hook_type(char)[:item],
          lore_hook_pet: Lorehooks.lore_hook_type(char)[:pet],
          lore_hook_ancestry: Lorehooks.lore_hook_type(char)[:ancestry],
          plot_prefs: Website.format_markdown_for_html(char.plot_prefs)
        }
      end

      # Gets custom fields for the character profile editor.
      #
      # @param [Character] char - The character being requested.
      # @param [Character] viewer - The character editing the profile.
      #
      # @return [Hash] - A hash containing custom fields and values.
      #    Multi-line text strings must be formatted for editing.
      # @example
      #    return { goals: Website.format_input_for_html(char.goals) }
      def self.get_fields_for_editing(char, viewer)
        return {
          plot_prefs: Website.format_input_for_html(char.plot_prefs)
        }
      end

      # Gets custom fields for character creation (chargen).
      #
      # @param [Character] char - The character being requested.
      #
      # @return [Hash] - A hash containing custom fields and values.
      #    Multi-line text strings must be formatted for editing.
      # @example
      #    return { goals: Website.format_input_for_html(char.goals) }
      def self.get_fields_for_chargen(char)
        return {}
      end

      # Saves fields from profile editing.
      #
      # @param [Character] char - The character being updated.
      # @param [Hash] char_data - A hash of character fields and values. Your custom fields
      #    will be in char_data[:custom]. Multi-line text strings should be formatted for MUSH.
      #
      # @return [Array] - A list of error messages. Return an empty array ([]) if there are no errors.
      # @example
      #        char.update(goals: Website.format_input_for_mush(char_data[:custom][:goals]))
      #        return []
      def self.save_fields_from_profile_edit(char, char_data)
        char.update(plot_prefs: Website.format_input_for_mush(char_data[:custom][:plot_prefs]))
      end

      # Saves fields from character creation (chargen).
      #
      # @param [Character] char - The character being updated.
      # @param [Hash] chargen_data - A hash of character fields and values. Your custom fields
      #    will be in chargen_data[:custom]. Multi-line text strings should be formatted for MUSH.
      #
      # @return [Array] - A list of error messages. Return an empty array ([]) if there are no errors.
      # @example
      #        char.update(goals: Website.format_input_for_mush(chargen_data[:custom][:goals]))
      #        return []
      def self.save_fields_from_chargen(char, chargen_data)
        return []
      end

    end
  end
end
