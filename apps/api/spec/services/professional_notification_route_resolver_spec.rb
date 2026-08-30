# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalNotificationRouteResolver do
  subject(:resolver) { described_class.new }

  it "defines one destination for every notification type" do
    mapped_types = described_class::STATIC_ROUTES.keys +
      described_class::QUOTE_TYPES +
      described_class::SERVICE_JOB_TYPES +
      ["customer_recommendation_published"]

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
  end

  it "builds quote and service destinations from semantic UUID parameters" do
    quote_id = "9b1fc90e-7a48-4c06-83de-88f22837435b"
    quote = instance_double(
      Notification,
      notification_type: "quote_approved",
      route_params: {"quote_id" => quote_id}
    )
    service_job_id = "22b68092-1e01-4d95-9954-907ecaabc707"
    service_job = instance_double(
      Notification,
      notification_type: "service_completion_confirmed",
      route_params: {"service_job_id" => service_job_id}
    )

    expect(resolver.call(quote)).to eq("/app/professional/quotes/new?quote=#{quote_id}")
    expect(resolver.call(service_job)).to eq("/app/professional/services/#{service_job_id}")
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
