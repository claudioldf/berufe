# frozen_string_literal: true

class CustomerRecommendationPolicy < ApplicationPolicy
  def index?
    active_user? && user.professional?
  end

  def update?
    owns_recommendation?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless active_user? && user.professional?

      scope.joins(service_job: :quote)
        .where(quotes: {professional_id: user.professional_profile.id})
    end
  end

  private

  def owns_recommendation?
    active_user? && user.professional? && record.service_job.professional.user_account_id == user.id
  end
end
