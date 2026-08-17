# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaUploadPolicy do
  let!(:owner) { create_account(phone: "+5547999998111") }
  let!(:other) { create_account(phone: "+5547999998112") }
  let!(:admin) { create_account(phone: "+5547999998113", role: "admin") }
  let!(:suspended) { create_account(phone: "+5547999998114", status: "suspended") }
  let!(:profile) { ProfessionalProfile.create!(user_account: owner, display_name: "Ana Souza") }
  let!(:upload) do
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      declared_content_type: "image/png",
      declared_byte_size: 10,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 10.minutes.from_now
    )
  end

  it "allows only the active owner to create and transition uploads" do
    policy = described_class.new(owner, upload)

    expect(policy.show?).to be(true)
    expect(policy.create?).to be(true)
    expect(policy.update?).to be(true)
    expect(described_class.new(other, upload).update?).to be(false)
    expect(described_class.new(suspended, upload).update?).to be(false)
  end

  it "allows active administrators to inspect without mutating private uploads" do
    policy = described_class.new(admin, upload)

    expect(policy.show?).to be(true)
    expect(policy.create?).to be(false)
    expect(policy.update?).to be(false)
  end

  private

  def create_account(phone:, role: "professional", status: "active")
    if role == "admin"
      UserAccount.create!(
        email: "media-admin@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        role:,
        status:
      )
    else
      UserAccount.create!(phone_e164: phone, role:, status:)
    end
  end
end
