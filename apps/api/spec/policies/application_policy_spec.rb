# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(nil, UserAccount.new) }

  it "denies every record action and resolves an empty scope by default" do
    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
    expect(described_class::Scope.new(nil, UserAccount).resolve).to be_empty
  end
end
