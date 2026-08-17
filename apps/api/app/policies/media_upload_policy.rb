# frozen_string_literal: true

class MediaUploadPolicy < ApplicationPolicy
  def show?
    owns_profile? || active_admin?
  end

  def create?
    owns_profile?
  end

  def update?
    owns_profile?
  end

  private

  def owns_profile?
    active_user? && user.professional? && record.professional_profile.user_account_id == user.id
  end
end
