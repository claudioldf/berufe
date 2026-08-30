# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:account) { create_registered_account("+5547999973001") }

  it "accepts only server-known types, internal routes, and a consistent read state" do
    notification = build_notification(account:)
    expect(notification).to be_valid

    notification.notification_type = "customer_authored_copy"
    notification.route = "https://untrusted.example/activity"
    notification.status = "read"
    expect(notification).not_to be_valid
    expect(notification.errors).to include(:notification_type, :route, :read_at)
  end

  it "keeps read status irreversible" do
    notification = build_notification(account:)
    notification.save!
    notification.update!(status: "read", read_at: Time.current)

    notification.assign_attributes(status: "unread", read_at: nil)
    expect(notification).not_to be_valid
    expect(notification.errors[:status]).to be_present
  end

  it "enforces globally unique event idempotency keys" do
    build_notification(account:).save!
    duplicate = build_notification(account:)

    expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  def create_registered_account(phone)
    UserAccount.create!(
      phone_e164: phone,
      role: "professional",
      status: "active",
      phone_verified_at: 2.minutes.ago,
      registered_at: 1.minute.ago,
      terms_accepted_at: 1.minute.ago,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
  end

  def build_notification(account:)
    described_class.new(
      recipient_user_account: account,
      notification_type: "quote_approved",
      title: "Orçamento aprovado",
      description: "Um cliente aprovou um orçamento.",
      route: "/app/professional/quotes/new?quote=quote-id",
      idempotency_key: "quote:quote-id:revision:1:approved",
      occurred_at: Time.current
    )
  end
end
