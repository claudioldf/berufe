# frozen_string_literal: true

class ServiceCategoryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.is_active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active.ordered
    end
  end
end
