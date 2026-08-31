# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalNotificationRouteResolver do
  subject(:resolver) { described_class.new }

  it "defines one destination for every notification type" do
    mapped_types = described_class::STATIC_ROUTES.keys +
      described_class::QUOTE_TYPES +
      described_class::SERVICE_JOB_TYPES +
      ["quote_approved", "customer_recommendation_published"]

    expect(mapped_types).to match_array(Notification::TYPES)
    expect(mapped_types.uniq.length).to eq(mapped_types.length)
  end

  it "resolves every static destination from the notification type" do
    described_class::STATIC_ROUTES.each do |notification_type, expected_route|
      notification = instance_double(
        Notification,
        notification_type:,
        route_params: {},
        recipient_user_account: nil
      )

      expect(resolver.call(notification)).to eq(expected_route)
    end

    expect(described_class::STATIC_ROUTES.fetch("profile_moderation_hidden")).to eq(
      "/app/professional"
    )
  end

  it "builds quote and service destinations from semantic UUID parameters" do
    quote_id = "9b1fc90e-7a48-4c06-83de-88f22837435b"
    quote = instance_double(
      Notification,
      notification_type: "quote_change_requested",
      route_params: {"quote_id" => quote_id}
    )
    service_job_id = "22b68092-1e01-4d95-9954-907ecaabc707"
    service_job_notification = instance_double(
      Notification,
      notification_type: "service_completion_issue_reported",
      route_params: {"service_job_id" => service_job_id}
    )

    expect(resolver.call(quote)).to eq("/app/professional/quotes/new?quote=#{quote_id}")
    expect(resolver.call(service_job_notification)).to eq(
      "/app/professional/services/#{service_job_id}"
    )
  end

  it "resolves an approved quote's destination to its resulting service job, at read time" do
    account = UserAccount.create!(phone_e164: "+5547999997611", role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
    make_profile_publicly_eligible(profile)
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {id: nil, name: "Marina Cliente", whatsapp_e164: "+5547999912611", email: nil},
        service_description: "Instalação de luminárias",
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        items: [{description: "Instalação", quantity: 1, unit: "ponto", unit_price: 100}]
      }
    )
    not_yet_approved = instance_double(
      Notification,
      notification_type: "quote_approved",
      route_params: {"quote_id" => quote.id}
    )
    expect(resolver.call(not_yet_approved)).to eq(
      "/app/professional/quotes/new?quote=#{quote.id}"
    )

    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]

    resolved = instance_double(
      Notification,
      notification_type: "quote_approved",
      route_params: {"quote_id" => quote.id}
    )
    expect(resolver.call(resolved)).to eq(
      "/app/professional/services/#{service_job.id}"
    )
  end

  it "uses the recipient profile's current slug and falls back when the profile is absent" do
    profile = instance_double(ProfessionalProfile, public_slug: "slug-atual")
    account = instance_double(UserAccount, professional_profile: profile)
    notification = instance_double(
      Notification,
      notification_type: "customer_recommendation_published",
      route_params: {},
      recipient_user_account: account
    )

    expect(resolver.call(notification)).to eq(
      "/profissionais/slug-atual#customer-recommendations-title"
    )
    allow(account).to receive(:professional_profile).and_return(nil)
    expect(resolver.call(notification)).to eq("/app/professional/profile")
  end
end
