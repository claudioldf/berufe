# frozen_string_literal: true

class AdminSearchAuditPolicy < ApplicationPolicy
  def index?
    active_admin?
  end
end
