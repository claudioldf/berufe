# frozen_string_literal: true

class AdminEmail
  def self.normalize(value)
    value.to_s.strip.downcase.presence
  end
end
