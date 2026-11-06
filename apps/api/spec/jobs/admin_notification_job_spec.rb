# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNotificationJob do
  def create_admin(email:, status: "active")
    UserAccount.create!(
      role: "admin", status:, email:, email_verified_at: Time.current,
      password: "Str0ng!Passw0rd#1", password_confirmation: "Str0ng!Passw0rd#1"
    )
  end

  it "enqueues one delivery per active administrator with an e-mail" do
    first = create_admin(email: "one@example.com")
    second = create_admin(email: "two@example.com")
    create_admin(email: "suspended@example.com", status: "suspended")
    UserAccount.create!(role: "professional", status: "active", email: "pro@example.com")
    subject_id = SecureRandom.uuid

    expect do
      described_class.perform_now("professional_registered", subject_id)
    end.to have_enqueued_job(AdminNotificationDeliveryJob).exactly(2).times
      .and have_enqueued_job(AdminNotificationDeliveryJob).with("professional_registered", subject_id, first.id)
      .and have_enqueued_job(AdminNotificationDeliveryJob).with("professional_registered", subject_id, second.id)
  end

  it "rejects unknown events" do
    expect { described_class.perform_now("nope", SecureRandom.uuid) }.to raise_error(ArgumentError)
  end
end
