# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNotificationJob do
  def with_recipients(emails)
    config = Rails.application.config.x.berufe
    allow(config).to receive(:environment).and_return(config.environment.with(admin_notification_emails: emails))
  end

  it "enqueues one delivery per configured address" do
    with_recipients(%w[one@example.com two@example.com])
    subject_id = SecureRandom.uuid

    expect do
      described_class.perform_now("professional_registered", subject_id)
    end.to have_enqueued_job(AdminNotificationDeliveryJob).exactly(2).times
      .and have_enqueued_job(AdminNotificationDeliveryJob).with("professional_registered", subject_id, "one@example.com")
      .and have_enqueued_job(AdminNotificationDeliveryJob).with("professional_registered", subject_id, "two@example.com")
  end

  it "does nothing when no addresses are configured" do
    with_recipients([])

    expect do
      described_class.perform_now("professional_registered", SecureRandom.uuid)
    end.not_to have_enqueued_job(AdminNotificationDeliveryJob)
  end

  it "rejects unknown events" do
    expect { described_class.perform_now("nope", SecureRandom.uuid) }.to raise_error(ArgumentError)
  end
end
