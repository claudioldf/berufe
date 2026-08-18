# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationPolicy do
  it "permits only active administrators" do
    admin = UserAccount.new(role: "admin", status: "active")
    professional = UserAccount.new(role: "professional", status: "active")
    suspended_admin = UserAccount.new(role: "admin", status: "suspended")

    expect(described_class.new(admin, :moderation)).to be_manage
    expect(described_class.new(professional, :moderation)).not_to be_manage
    expect(described_class.new(suspended_admin, :moderation)).not_to be_manage
    expect(described_class.new(nil, :moderation)).not_to be_manage
  end
end
