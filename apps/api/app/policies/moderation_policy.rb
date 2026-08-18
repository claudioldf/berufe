# frozen_string_literal: true

class ModerationPolicy < ApplicationPolicy
  def manage?
    active_admin?
  end
end
