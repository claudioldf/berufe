# frozen_string_literal: true

class ApplicationSessionPolicy < ApplicationPolicy
  def show?
    owns_session?
  end

  def destroy?
    owns_session?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless active_user?

      scope.where(user_account_id: user.id)
    end
  end

  private

  def owns_session?
    active_user? && [record.user_account_id, record.impersonated_user_account_id].include?(user.id)
  end
end
