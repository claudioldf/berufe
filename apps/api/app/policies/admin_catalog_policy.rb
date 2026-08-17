# frozen_string_literal: true

class AdminCatalogPolicy < ApplicationPolicy
  def manage?
    active_admin?
  end
end
