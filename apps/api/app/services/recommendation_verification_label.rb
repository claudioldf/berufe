# frozen_string_literal: true

class RecommendationVerificationLabel
  EMAIL = "Link enviado por e-mail"
  WHATSAPP = "Link enviado por WhatsApp"

  def self.call(recommendation)
    recommendation.email_channel? ? EMAIL : WHATSAPP
  end
end
