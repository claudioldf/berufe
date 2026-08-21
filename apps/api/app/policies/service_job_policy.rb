# frozen_string_literal: true

class ServiceJobPolicy < ApplicationPolicy
  def index?
    active_user? && (user.professional? || user.admin?)
  end

  def show?
    owns_service_job? || active_admin?
  end

  def update?
    owns_service_job?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless active_user?
      return scope.all if user.admin?
      return scope.none unless user.professional?

      scope.joins(quote: :professional)
        .where(professional_profiles: {user_account_id: user.id})
    end
  end

  private

  def owns_service_job?
    active_user? && user.professional? && record.professional.user_account_id == user.id
  end
end
