module AresMUSH
  class Character
    attribute :looking_for_rp, :type => DataType::Boolean, :default => false
    attribute :looking_for_rp_expires_at, :type => Ohm::DataTypes::DataType::Time
  end
end