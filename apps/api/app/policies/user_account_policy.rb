# frozen_string_literal: true

class UserAccountPolicy < ApplicationPolicy
  def show?
    active_user? && (owns_account? || user.admin?)
  end

  def update?
    active_user? && owns_account?
  end

  def complete_registration?
    active_user? && owns_account? && user.professional?
  end

  def request_data_erasure?
    active_user? && owns_account? && user.professional? && record.professional_profile.present?
  end

  def suspend?
    active_admin?
  end

  def revoke_all_sessions?
    active_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless active_user?
      return scope.all if user.admin?

      scope.where(id: user.id)
    end
  end

  private

  def owns_account?
    record.id == user.id
  end
end
