# frozen_string_literal: true

class AdminProfessionalPolicy < ApplicationPolicy
  def manage?
    active_admin?
  end
end
