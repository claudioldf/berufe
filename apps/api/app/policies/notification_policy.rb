# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index?
    eligible_professional?
  end

  def update?
    eligible_professional? && record.recipient_user_account_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active? && user.professional? && user.registered?

      scope.where(recipient_user_account_id: user.id)
    end
  end

  private

  def eligible_professional?
    active_user? && user.professional? && user.registered?
  end
end
