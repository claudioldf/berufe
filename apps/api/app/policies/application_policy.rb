# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end

    private

    def active_user?
      user&.active? || false
    end
  end

  private

  def active_user?
    user&.active? || false
  end

  def active_admin?
    active_user? && user.admin?
  end

  def owns_record?
    active_user? && record.respond_to?(:user_account_id) && record.user_account_id == user.id
  end
end
