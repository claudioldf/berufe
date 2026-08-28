# frozen_string_literal: true

class ProfessionalProfileSubmitter
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("professional profile is not ready for submission")
    end
  end

  def call(profile:)
    profile.with_lock do
      revision = profile.working_revision
      raise ActiveRecord::RecordNotFound, "professional profile revision" unless revision

      return profile if already_published?(profile)

      validate_state!(profile, revision)
      validate_checklist!(profile, revision)

      submitted_at = Time.current
      revision.update!(
        status: "pending_review",
        submitted_at:,
        reviewed_at: nil,
        rejection_reason: nil
      )
      profile.update!(
        published_revision: revision,
        published_photo: profile.working_photo,
        profile_status: "published",
        published_at: profile.published_at || submitted_at
      )
    end
    profile.reload
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def already_published?(profile)
    profile.has_self_service_publication? && profile.self_service_publicly_available?
  end

  def validate_state!(profile, revision)
    return if profile.profile_status != "suspended" && revision.self_service? &&
      revision.status.in?(%w[draft pending_review])

    raise Invalid.new(base: ["o perfil não está disponível para envio"])
  end

  def validate_checklist!(profile, revision)
    errors = {}
    errors[:identity] = ["complete nome, data de nascimento e contato"] unless identity_complete?(profile, revision)
    errors[:photo] = ["envie uma foto de perfil processada"] unless photo_complete?(profile)
    errors[:services] = ["escolha ao menos um serviço ativo e defina exatamente um principal"] unless services_complete?(revision)
    errors[:coverage] = ["selecione uma cidade inteira ou ao menos um bairro dela"] unless coverage_complete?(revision)
    raise Invalid.new(errors) if errors.any?
  end

  def identity_complete?(profile, revision)
    revision.display_name.present? &&
      profile.birthdate.present? &&
      (revision.whatsapp_e164.presence || profile.user_account.phone_e164).present?
  end

  def photo_complete?(profile)
    profile.working_photo&.status&.in?(%w[pending_review approved])
  end

  def services_complete?(revision)
    selections = revision.professional_profile_services.includes(service: :category).to_a
    selections.any? &&
      selections.count(&:is_primary?) == 1 &&
      selections.all? { |selection| selection.service.is_active? && selection.service.category.is_active? }
  end

  def coverage_complete?(revision)
    return false unless revision.coverage_city

    areas = revision.professional_profile_service_areas.includes(:neighborhood).to_a
    return areas.empty? if revision.covers_whole_city?
    return false if areas.empty?

    areas.all? { |area| area.neighborhood&.city_code == revision.coverage_city_code }
  end
end
