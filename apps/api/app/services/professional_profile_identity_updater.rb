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
    normalized = normalize(profile, attributes)
    validate!(normalized)
    profile.with_lock do
      expire_identity_if_birthdate_changed!(profile, normalized.delete(:birthdate))
      editor = ProfessionalProfileRevisionEditor.new
      revision = editor.call(profile:)
      revision.update!(normalized)
      editor.synchronize_review_state!(profile:)
    end
    profile.reload
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

  def normalize(profile, attributes)
    instagram = normalize_social(attributes[:instagram], :instagram)
    youtube = normalize_social(attributes[:youtube], :youtube)
    {
      display_name: attributes[:display_name].to_s.squish,
      headline: attributes[:headline].to_s.squish.presence,
      bio: attributes[:bio].to_s.squish.presence,
      years_experience: normalize_experience(attributes[:years_experience]),
      whatsapp_e164: normalize_whatsapp(profile, attributes[:whatsapp]),
      instagram_url: instagram,
      youtube_url: youtube,
      birthdate: normalize_birthdate(attributes[:birthdate])
    }
  end

  def normalize_whatsapp(profile, value)
    return profile.user_account.phone_e164 if value.blank?

    BrazilianPhoneNumber.normalize(value)
  end

  def normalize_birthdate(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
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
    length_error(field_errors, :headline, attributes[:headline], 1..120) if attributes[:headline]
    length_error(field_errors, :bio, attributes[:bio], 1..2500) if attributes[:bio]
    birthdate = attributes[:birthdate]
    if birthdate.nil? || birthdate > Date.current || birthdate < 120.years.ago.to_date
      field_errors[:birthdate] = ["informe uma data de nascimento válida"]
    end
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

  def expire_identity_if_birthdate_changed!(profile, birthdate)
    return profile.update!(birthdate:) if profile.birthdate == birthdate

    now = Time.current
    profile.verification_requests.identity.where(status: %w[pending_review approved]).update_all(
      status: "expired",
      public_label: nil,
      verified_at: nil,
      identity_match_confirmed_at: nil,
      expired_at: now,
      updated_at: now
    )
    profile.update!(birthdate:)
  end
end
