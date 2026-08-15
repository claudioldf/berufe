# frozen_string_literal: true

class ProfessionalProfilePolicy < ApplicationPolicy
  def show?
    owns_record? || active_admin?
  end

  def update?
    owns_record?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless active_user?
      return scope.all if user.admin?

      scope.where(user_account_id: user.id)
    end
  end
end
