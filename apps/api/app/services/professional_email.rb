# frozen_string_literal: true

class ProfessionalEmail
  class Invalid < StandardError; end

  MAXIMUM_LENGTH = 254

  def self.normalize(value)
    email = value.to_s.strip.downcase
    unless email.length.between?(3, MAXIMUM_LENGTH) && URI::MailTo::EMAIL_REGEXP.match?(email)
      raise Invalid
    end

    email
  end
end
