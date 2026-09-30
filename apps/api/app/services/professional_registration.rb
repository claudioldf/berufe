# frozen_string_literal: true

class ProfessionalRegistration
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional registration")
    end
  end

  def call(user_account:, authentication_method:, display_name:, accepted:, phone: nil, email: nil, now: Time.current)
    validate_account!(user_account)
    normalized_name = display_name.to_s.squish
    validate_input!(display_name: normalized_name, accepted:)
    contact = normalize_complementary_contact(authentication_method:, phone:, email:)

    user_account.with_lock do
      if user_account.registration_completed?
        next user_account.professional_profile
      end

      validate_contact_change!(user_account:, contact:)

      profile = user_account.professional_profile
      if profile&.creation_source == "external"
        prepare_claimed_profile!(profile, display_name: normalized_name)
      else
        profile ||= user_account.build_professional_profile(creation_source: "self_service")
        profile.display_name = normalized_name
        profile.profile_status = "draft"
        profile.save!
      end
      user_account.assign_attributes(contact[:account_attribute] => contact[:value])
      user_account.update!(
        terms_accepted_at: now,
        terms_version: LegalDocumentVersions::TERMS,
        privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE,
        registered_at: user_account.registered_at || now
      )
      profile
    end
  rescue ActiveRecord::RecordNotUnique
    raise Invalid.new(contact[:request_field] => ["não pode ser usado neste cadastro"])
  end

  private

  def validate_account!(user_account)
    return if user_account.active? && user_account.professional? && user_account.verified?

    raise Invalid.new(base: ["Esta conta não pode concluir o cadastro profissional."])
  end

  def normalize_complementary_contact(authentication_method:, phone:, email:)
    case authentication_method
    when "sms_otp"
      raise Invalid.new(email: ["informe um e-mail válido"]) if phone.present?

      {
        account_attribute: :email,
        request_field: :email,
        value: ProfessionalEmail.normalize(email)
      }
    when "email_otp"
      raise Invalid.new(phone: ["informe um celular brasileiro com DDD"]) if email.present?

      {
        account_attribute: :phone_e164,
        request_field: :phone,
        value: BrazilianPhoneNumber.normalize(phone)
      }
    else
      raise Invalid.new(base: ["Esta sessão não pode concluir o cadastro profissional."])
    end
  rescue ProfessionalEmail::Invalid
    raise Invalid.new(email: ["informe um e-mail válido"])
  rescue BrazilianPhoneNumber::Invalid
    raise Invalid.new(phone: ["informe um celular brasileiro com DDD"])
  end

  def validate_contact_change!(user_account:, contact:)
    account_attribute = contact[:account_attribute]
    request_field = contact[:request_field]
    value = contact[:value]
    verification_attribute = (account_attribute == :email) ? :email_verified_at : :phone_verified_at

    if user_account.public_send(verification_attribute).present? && user_account.public_send(account_attribute) != value
      raise Invalid.new(request_field => ["não pode substituir um contato já confirmado"])
    end

    return unless UserAccount.where(account_attribute => value).where.not(id: user_account.id).exists?

    raise Invalid.new(request_field => ["não pode ser usado neste cadastro"])
  end

  def prepare_claimed_profile!(profile, display_name:)
    return if profile.working_revision&.self_service?

    source = profile.published_revision || profile.working_revision
    raise ActiveRecord::RecordNotFound, "external profile revision" unless source

    revision = profile.revisions.create!(
      version: profile.revisions.maximum(:version).to_i + 1,
      profile_type: "self_service",
      coverage_city_code: source.coverage_city_code,
      covers_whole_city: source.covers_whole_city,
      display_name:,
      headline: source.headline,
      bio: source.bio,
      years_experience: source.years_experience,
      whatsapp_e164: source.whatsapp_e164,
      instagram_url: source.instagram_url,
      youtube_url: source.youtube_url
    )
    source.professional_profile_services.find_each do |selection|
      revision.professional_profile_services.create!(
        service_id: selection.service_id,
        is_primary: selection.is_primary,
        note: selection.note
      )
    end
    source.professional_profile_service_areas.find_each do |area|
      revision.professional_profile_service_areas.create!(neighborhood_code: area.neighborhood_code)
    end
    profile.update!(working_revision: revision)
  end

  def validate_input!(display_name:, accepted:)
    field_errors = {}
    field_errors[:display_name] = ["deve ter entre 3 e 70 caracteres"] unless display_name.length.between?(3, 70)
    field_errors[:accepted] = ["deve ser confirmado"] unless accepted == true
    raise Invalid.new(field_errors) if field_errors.any?
  end
end
