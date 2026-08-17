# frozen_string_literal: true

class ProfessionalProfileIdentityUpdater
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional profile identity")
    end
  end

  def call(profile:, attributes:)
    normalized = normalize(attributes)
    validate!(normalized)
    profile.update!(normalized)
    profile
  rescue BrazilianPhoneNumber::Invalid
    raise Invalid.new(whatsapp: ["informe um celular brasileiro com DDD"])
  rescue SocialProfileUrl::Invalid => error
    field_errors = if error.message == "youtube"
      {youtube: [social_error(:youtube)]}
    else
      {instagram: [social_error(:instagram)]}
    end
    raise Invalid.new(field_errors)
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def normalize(attributes)
    instagram = normalize_social(attributes[:instagram], :instagram)
    youtube = normalize_social(attributes[:youtube], :youtube)
    {
      display_name: attributes[:display_name].to_s.squish,
      headline: attributes[:headline].to_s.squish,
      bio: attributes[:bio].to_s.squish,
      years_experience: normalize_experience(attributes[:years_experience]),
      whatsapp_e164: BrazilianPhoneNumber.normalize(attributes[:whatsapp]),
      instagram_url: instagram,
      youtube_url: youtube
    }
  end

  def normalize_social(value, platform)
    SocialProfileUrl.normalize(value, platform:)
  rescue SocialProfileUrl::Invalid
    raise SocialProfileUrl::Invalid, platform.to_s
  end

  def normalize_experience(value)
    return nil if value.nil? || value == ""

    Integer(value, exception: false)
  end

  def validate!(attributes)
    field_errors = {}
    length_error(field_errors, :display_name, attributes[:display_name], 3..70)
    length_error(field_errors, :headline, attributes[:headline], 1..120)
    length_error(field_errors, :bio, attributes[:bio], 1..500)
    experience = attributes[:years_experience]
    if !experience.nil? && (!experience.is_a?(Integer) || !experience.between?(0, 70))
      field_errors[:years_experience] = ["deve estar entre 0 e 70"]
    end
    raise Invalid.new(field_errors) if field_errors.any?
  end

  def length_error(errors, field, value, range)
    return if range.cover?(value.length)

    errors[field] = ["deve ter entre #{range.begin} e #{range.end} caracteres"]
  end

  def social_error(platform)
    example = (platform == :instagram) ? "@perfil ou instagram.com/perfil" : "@canal ou youtube.com/@canal"
    "informe um perfil válido, como #{example}"
  end
end
