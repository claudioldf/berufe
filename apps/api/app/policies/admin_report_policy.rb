# frozen_string_literal: true

class AdminReportPolicy < ApplicationPolicy
  def show?
    active_admin?
  end
end
