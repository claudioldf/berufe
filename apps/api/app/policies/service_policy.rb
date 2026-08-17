# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.is_active? && record.category.is_active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.publicly_active.includes(:category).ordered
    end
  end
end
