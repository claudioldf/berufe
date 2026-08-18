# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public professional WhatsApp handoffs", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Contato público",
      slug: "contato-publico",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Instalação elétrica pública",
      slug: "instalacao-eletrica-publica",
      icon: "i-lucide-zap",
      description: "Instalação elétrica residencial.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let(:profile) { create_published_profile(phone: "+5547999997951", name: "Contato Público") }
  let(:profile_token) do
    PublicProfileInteractionToken.new.issue(
      professional_id: profile.id,
      service_id: service.id
    )
  end

  before do
    Rails.application.config.x.berufe.public_interaction_cache.clear
  end

  it "counts one public-profile handoff and redirects retries to the same allowlisted WhatsApp URL" do
    2.times do |index|
      get endpoint(profile),
        params: {source: "public_profile", interactionToken: profile_token},
        headers: browser_headers("whatsapp-profile-302-#{index}")

      expect(response).to have_http_status(:found)
      expect(response.headers.fetch("Cache-Control")).to eq("no-store")
      expect_safe_redirect(service_name: service.name, phone: profile.published_revision.whatsapp_e164)
    end

    expect(ProfessionalDailyMetric.sole).to have_attributes(
      professional: profile,
      whatsapp_clicks: 1,
      whatsapp_clicks_public_profile: 1,
      whatsapp_clicks_search_result: 0
    )
    assert_api_conform(status: 302)
  end

  it "attributes search-result handoffs and marks the anonymous search-level outcome once" do
    event = SearchEvent.create!(
      service:,
      query_text_normalized: "instalacao eletrica publica",
      city_code: "Joinville",
      result_count: 1
    )
    token = PublicInteractionToken.new.issue(search_event_id: event.id, service_id: service.id)

    get endpoint(profile),
      params: {source: "search_result", interactionToken: token},
      headers: browser_headers("whatsapp-search-302")

    expect(response).to have_http_status(:found)
    expect(ProfessionalDailyMetric.sole).to have_attributes(
      whatsapp_clicks: 1,
      whatsapp_clicks_public_profile: 0,
      whatsapp_clicks_search_result: 1
    )
    expect(event.reload.whatsapp_handoff_occurred).to be(true)
    assert_api_conform(status: 302)
  end

  it "redirects obvious bots and link previews without counting them" do
    ["facebookexternalhit/1.1", "WhatsApp/2.26", "Googlebot/2.1"].each_with_index do |agent, index|
      get endpoint(profile),
        params: {source: "public_profile", interactionToken: profile_token},
        headers: {"User-Agent" => agent, "X-Request-Id" => "whatsapp-bot-#{index}"}

      expect(response).to have_http_status(:found)
      expect(URI.parse(response.location).host).to eq("wa.me")
    end
    expect(ProfessionalDailyMetric.count).to eq(0)
  end

  it "rejects missing, invalid, expired-kind, unrelated-service, and cross-profile interactions" do
    other = create_published_profile(phone: "+5547999997952", name: "Outro Contato")
    other_token = PublicProfileInteractionToken.new.issue(
      professional_id: other.id,
      service_id: service.id
    )
    unrelated = Service.create!(
      category:,
      name: "Pintura sem oferta",
      slug: "pintura-sem-oferta",
      icon: "i-lucide-paintbrush",
      description: "Serviço que o perfil não oferece.",
      aliases: [],
      is_active: true,
      sort_order: 1
    )
    unrelated_token = PublicInteractionToken.new.issue(
      search_event_id: SecureRandom.uuid,
      service_id: unrelated.id
    )
    cases = [
      {},
      {source: "invalid", interactionToken: profile_token},
      {source: "public_profile", interactionToken: "invalid"},
      {source: "public_profile", interactionToken: other_token},
      {source: "search_result", interactionToken: profile_token},
      {source: "search_result", interactionToken: unrelated_token}
    ]

    cases.each_with_index do |query, index|
      get endpoint(profile),
        params: query,
        headers: browser_headers("whatsapp-422-#{index}")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end
    expect(ProfessionalDailyMetric.count).to eq(0)
    assert_api_conform(status: 422)
  end

  it "uses the same generic not-found response for an ineligible profile or unavailable approved contact" do
    ineligible = create_published_profile(phone: "+5547999997953", name: "Contato Suspenso")
    ineligible.user_account.update!(status: "suspended")
    missing_contact = create_published_profile(phone: nil, name: "Contato Ausente")
    interactions = {
      ineligible => PublicProfileInteractionToken.new.issue(
        professional_id: ineligible.id,
        service_id: service.id
      ),
      missing_contact => PublicProfileInteractionToken.new.issue(
        professional_id: missing_contact.id,
        service_id: service.id
      )
    }

    interactions.each_with_index do |(candidate, token), index|
      get endpoint(candidate),
        params: {source: "public_profile", interactionToken: token},
        headers: browser_headers("whatsapp-404-#{index}")

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    end
    assert_api_conform(status: 404)
  end

  it "contains metric and cache failures without blocking a valid redirect" do
    recorder = instance_double(PublicWhatsappHandoffRecorder, call: false)
    allow(PublicWhatsappHandoffRecorder).to receive(:new).and_return(recorder)

    get endpoint(profile),
      params: {source: "public_profile", interactionToken: profile_token},
      headers: browser_headers("whatsapp-metric-failure")

    expect(response).to have_http_status(:found)
    expect(URI.parse(response.location).host).to eq("wa.me")
    expect(recorder).to have_received(:call)
  end

  it "returns a safe unavailable response when public eligibility cannot be read" do
    allow(ProfessionalProfile).to receive(:publicly_eligible)
      .and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/professionals/#{SecureRandom.uuid}/whatsapp",
      params: {source: "public_profile", interactionToken: "signed-but-unread"},
      headers: browser_headers("whatsapp-503")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def endpoint(candidate)
    "/api/v1/public/professionals/#{candidate.id}/whatsapp"
  end

  def browser_headers(request_id)
    {
      "User-Agent" => "Mozilla/5.0 AppleWebKit/537.36 Chrome/140 Safari/537.36",
      "X-Request-Id" => request_id
    }
  end

  def expect_safe_redirect(service_name:, phone:)
    uri = URI.parse(response.location)
    expect(uri).to have_attributes(
      scheme: "https",
      host: "wa.me",
      path: "/#{phone.delete_prefix("+")}"
    )
    expect(URI.decode_www_form(uri.query).to_h.fetch("text")).to eq(
      "Olá! Vi seu perfil na Berufe para #{service_name}."
    )
  end

  def create_published_profile(phone:, name:)
    account_phone = phone || "+5547999997999"
    account = UserAccount.create!(phone_e164: account_phone, role: "professional", status: "active")
    record = ProfessionalProfile.create!(
      user_account: account,
      display_name: name,
      whatsapp_e164: phone
    )
    revision = record.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.update!(status: "approved", reviewed_at: Time.current)
    record.update!(profile_status: "published", published_revision: revision)
    record
  end
end
