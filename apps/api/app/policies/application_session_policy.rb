# frozen_string_literal: true

class ApplicationSessionPolicy < ApplicationPolicy
  def show?
    owns_record?
  end

  def destroy?
    owns_record?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless active_user?

      scope.where(user_account_id: user.id)
    end
  end
end
