# frozen_string_literal: true

class ProfessionalDashboardReadiness
  STEP_WEIGHT = 25

  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    current_steps = steps
    {
      percentage: current_steps.values.count(true) * STEP_WEIGHT,
      steps: current_steps
    }
  end

  private

  attr_reader :profile

  def steps
    {
      identity_contact: identity_contact_complete?,
      service_coverage: service_coverage_complete?,
      reviewable_portfolio: reviewable_portfolio?,
      approved_identity: approved_identity?
    }
  end

  def identity_contact_complete?
    revision = profile.working_revision
    phone = revision.whatsapp_e164 || profile.user_account.phone_e164
    !!(revision.display_name.present? &&
      profile.birthdate.present? &&
      profile.working_photo&.status&.in?(%w[pending_review approved]) &&
      phone.match?(UserAccount::BRAZILIAN_MOBILE_PATTERN))
  end

  def service_coverage_complete?
    revision = profile.working_revision
    selections = revision.professional_profile_services.includes(service: :category).to_a
    service = selections.any? &&
      selections.count(&:is_primary?) == 1 &&
      selections.all? { |selection| selection.service.is_active? && selection.service.category.is_active? }
    coverage = revision.professional_profile_service_areas.includes(:neighborhood).any? do |area|
      area.city_code == ProfessionalProfileServiceArea::JOINVILLE &&
        (area.neighborhood_code.nil? || area.neighborhood&.is_active?)
    end
    service && coverage
  end

  def reviewable_portfolio?
    profile.portfolio_items.active.exists?(status: %w[pending_review approved])
  end

  def approved_identity?
    profile.verification_requests.identity.exists?(status: "approved")
  end
end
