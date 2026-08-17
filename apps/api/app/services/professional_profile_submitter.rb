# frozen_string_literal: true

class ProfessionalProfileSubmitter
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("professional profile is not ready for submission")
    end
  end

  REVIEWABLE_STATUSES = %w[pending_review approved].freeze

  def call(profile:)
    profile.with_lock do
      revision = profile.working_revision
      raise ActiveRecord::RecordNotFound, "professional profile revision" unless revision

      return profile if already_submitted?(profile, revision)

      validate_state!(profile, revision)
      validate_checklist!(profile, revision)

      submitted_at = Time.current
      revision.update!(
        status: "pending_review",
        submitted_at:,
        reviewed_at: nil,
        rejection_reason: nil
      )
      profile.update!(profile_status: "pending_review")
    end
    profile.reload
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def already_submitted?(profile, revision)
    profile.profile_status == "pending_review" && revision.status == "pending_review"
  end

  def validate_state!(profile, revision)
    return if profile.profile_status == "draft" && revision.status.in?(%w[draft rejected])

    raise Invalid.new(base: ["o perfil não está disponível para envio"])
  end

  def validate_checklist!(profile, revision)
    errors = {}
    errors[:identity] = ["complete nome, apresentação, biografia e WhatsApp"] unless identity_complete?(revision)
    errors[:services] = ["escolha ao menos um serviço ativo e defina exatamente um principal"] unless services_complete?(revision)
    errors[:coverage] = ["selecione toda Joinville ou ao menos um bairro ativo"] unless coverage_complete?(revision)
    errors[:portfolio] = ["envie ao menos um trabalho para análise"] unless reviewable_portfolio?(profile)
    errors[:verification] = ["envie sua identidade para análise"] unless reviewable_identity?(profile)
    raise Invalid.new(errors) if errors.any?
  end

  def identity_complete?(revision)
    revision.display_name.present? &&
      revision.headline.present? &&
      revision.bio.present? &&
      revision.whatsapp_e164.present?
  end

  def services_complete?(revision)
    selections = revision.professional_profile_services.includes(service: :category).to_a
    selections.any? &&
      selections.count(&:is_primary?) == 1 &&
      selections.all? { |selection| selection.service.is_active? && selection.service.category.is_active? }
  end

  def coverage_complete?(revision)
    areas = revision.professional_profile_service_areas.includes(:neighborhood).to_a
    return false if areas.empty?
    return true if areas.one? && areas.first.neighborhood_code.nil?

    areas.all? { |area| area.neighborhood_code.present? && area.neighborhood&.is_active? }
  end

  def reviewable_portfolio?(profile)
    profile.portfolio_items.active.where(status: REVIEWABLE_STATUSES).exists?
  end

  def reviewable_identity?(profile)
    profile.verification_requests
      .identity
      .where(status: REVIEWABLE_STATUSES)
      .joins(:verification_file)
      .exists?
  end
end
