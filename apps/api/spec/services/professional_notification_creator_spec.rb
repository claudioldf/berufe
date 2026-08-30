# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalNotificationCreator do
  it "creates server-owned copy once for an eligible registered professional" do
    account = create_account(phone: "+5547999973011", registered: true)
    now = Time.zone.parse("2026-08-30 12:00:00 UTC")

    2.times do
      described_class.new.call(
        recipient: account,
        notification_type: "relationship_request_received",
        route: "/app/professional/profile?tab=relacoes",
        idempotency_key: "relationship:relationship-id:requested",
        occurred_at: now
      )
    end

    expect(Notification.sole).to have_attributes(
      recipient_user_account: account,
      notification_type: "relationship_request_received",
      status: "unread",
      title: "Nova solicitação de conexão",
      description: "Um profissional quer adicionar uma conexão com você.",
      route: "/app/professional/profile?tab=relacoes",
      occurred_at: now,
      read_at: nil
    )
  end

  it "covers every persisted notification type with bounded static copy" do
    expect(described_class::COPY.keys).to match_array(Notification::TYPES)
    expect(described_class::COPY.values).to all(
      satisfy { |title, description| title.length.between?(1, 120) && description.length.between?(1, 240) }
    )
  end

  it "does not persist activity for unregistered, suspended, or non-professional accounts" do
    unregistered = create_account(phone: "+5547999973012", registered: false)
    suspended = create_account(phone: "+5547999973013", registered: true, status: "suspended")
    admin = UserAccount.create!(
      email: "notification-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )

    [unregistered, suspended, admin].each_with_index do |account, index|
      described_class.new.call(
        recipient: account,
        notification_type: "quote_approved",
        route: "/app/professional/quotes",
        idempotency_key: "ineligible:#{index}"
      )
    end

    expect(Notification.count).to eq(0)
  end

  def create_account(phone:, registered:, status: "active")
    attributes = {
      phone_e164: phone,
      role: "professional",
      status:
    }
    if registered
      attributes.merge!(
        phone_verified_at: 2.minutes.ago,
        registered_at: 1.minute.ago,
        terms_accepted_at: 1.minute.ago,
        terms_version: LegalDocumentVersions::TERMS,
        privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
      )
    end
    UserAccount.create!(attributes)
  end
end
