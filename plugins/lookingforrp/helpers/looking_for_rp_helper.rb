module AresMUSH
  module LookingForRp

    def self.set(char, duration)
      end_at = LookingForRp.end_at(duration)
      puts end_at
      char.update(looking_for_rp_expires_at: end_at)
      char.update(looking_for_rp: true)
    end

    def self.end_at(duration)
      Time.now + duration.hour
    end

    def self.expire(char)
      char.update(looking_for_rp: false)
    end

    def self.chars_looking_for_rp
      Chargen.approved_chars.select { |c| c.looking_for_rp == true }
    end

  end
end