# frozen_string_literal: true

class ProfessionalRegistration
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional registration")
    end
  end

  def call(user_account:, display_name:, accepted:, now: Time.current)
    validate_account!(user_account)
    normalized_name = display_name.to_s.squish
    validate_input!(display_name: normalized_name, accepted:)

    user_account.with_lock do
      if user_account.registration_completed?
        next user_account.professional_profile
      end

      profile = user_account.professional_profile
      if profile&.creation_source == "external"
        prepare_claimed_profile!(profile, display_name: normalized_name)
      else
        profile ||= user_account.build_professional_profile(creation_source: "self_service")
        profile.display_name = normalized_name
        profile.profile_status = "draft"
        profile.save!
      end
      user_account.update!(
        terms_accepted_at: now,
        terms_version: LegalDocumentVersions::TERMS,
        privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE,
        registered_at: user_account.registered_at || now
      )
      profile
    end
  end

  private

  def validate_account!(user_account)
    return if user_account.active? && user_account.professional? && user_account.phone_verified?

    raise Invalid.new(base: ["Esta conta não pode concluir o cadastro profissional."])
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
