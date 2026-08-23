# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shared quotes", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let!(:category) do
    ServiceCategory.create!(
      name: "Orçamentos",
      slug: "orcamentos",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista-orcamentos",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997441", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      whatsapp_e164: "+5547999997441"
    )
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end
  let(:quote) do
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Ana Paula",
          whatsapp_e164: "+5547999912041",
          email: "ana.paula@example.com"
        },
        service_description: "Iluminação da cozinha",
        discount_amount: 40,
        valid_until: "2026-01-01",
        notes: "Materiais definidos com a cliente.",
        items: [
          {description: "Instalação", quantity: 4, unit: "ponto", unit_price: 200},
          {description: "Revisão", quantity: 1, unit: "serviço", unit_price: 40}
        ]
      }
    )
  end

  before { publish_profile! }

  it "shares once, reproduces the stable token, and resolves only current public content" do
    photo = profile.published_photo
    first_shared_at = Time.zone.parse("2026-08-18 12:00:00 UTC")
    travel_to(first_shared_at) do
      share_quote(request_id: "quote-share-first", method: "copy")
    end

    expect(response).to have_http_status(:ok)
    first_url = response.parsed_body.dig("data", "share_url")
    whatsapp_url = response.parsed_body.dig("data", "whatsapp_url")
    token = URI(first_url).path.split("/").last
    expect(token).to match(/\Abq_[A-Za-z0-9_-]{43}\z/)
    expect(quote.reload).to have_attributes(
      status: "shared",
      shared_at: first_shared_at,
      share_token_hash: QuoteShareToken.digest(token)
    )
    expect(quote.attributes.to_json).not_to include(token)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(URI(whatsapp_url)).to have_attributes(host: "wa.me", path: "/5547999912041")
    whatsapp_message = URI.decode_www_form(URI(whatsapp_url).query).to_h.fetch("text")
    expect(whatsapp_message).to eq(
      "Olá! Preparei o orçamento #1 para você. Confira na Berufe: #{first_url}"
    )
    expect(whatsapp_message).not_to include("Ana Paula")
    expect(ProfessionalDailyMetric.sole.quotes_shared).to eq(1)
    assert_api_conform(status: 200)

    travel_to(first_shared_at + 1.hour) do
      share_quote(request_id: "quote-share-repeat", method: "whatsapp")
    end
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "share_url")).to eq(first_url)
    expect(quote.reload.shared_at).to eq(first_shared_at)
    expect(ProfessionalDailyMetric.sole.quotes_shared).to eq(2)
    assert_api_conform(status: 200)

    resolve_quote(token:, request_id: "quote-resolve-valid")
    expect(response).to have_http_status(:ok)
    expect(response.headers).to include(
      "Cache-Control" => "private, no-store",
      "Referrer-Policy" => "no-referrer",
      "X-Robots-Tag" => "noindex, nofollow"
    )
    data = response.parsed_body.fetch("data")
    expect(data.fetch("quote")).to include(
      "quote_number" => 1,
      "revision" => quote.reload.lock_version,
      "status" => "shared",
      "customer_name" => "Ana Paula",
      "service_description" => "Iluminação da cozinha",
      "service_address" => nil,
      "scheduled_on" => nil,
      "valid_until" => "2026-01-01",
      "notes" => "Materiais definidos com a cliente.",
      "subtotal_amount" => "840.00",
      "discount_amount" => "40.00",
      "total_amount" => "800.00",
      "customer_decision_message" => nil,
      "service_job" => nil,
      "items" => [
        {
          "description" => "Instalação",
          "quantity" => "4",
          "unit" => "ponto",
          "unit_price" => "200.00",
          "line_total" => "800.00",
          "sort_order" => 0
        },
        {
          "description" => "Revisão",
          "quantity" => "1",
          "unit" => "serviço",
          "unit_price" => "40.00",
          "line_total" => "40.00",
          "sort_order" => 1
        }
      ]
    )
    expect(data.fetch("professional")).to eq(
      "display_name" => "Ana Souza",
      "photo_url" => PublicProfilePhotoImageUrl.call(photo),
      "primary_service" => "Eletricista",
      "identity_verified" => false
    )
    expect(response.body).not_to include(
      token,
      quote.id,
      quote.share_token_hash,
      profile.published_revision.whatsapp_e164,
      photo.private_key,
      "+5547",
      "shared_at",
      "created_at"
    )
    assert_api_conform(status: 200)

    quote.update!(customer_name: "Conteúdo atualizado")
    create_approved_identity!
    resolve_quote(token:, request_id: "quote-resolve-live")
    expect(response.parsed_body.dig("data", "quote", "customer_name")).to eq("Conteúdo atualizado")
    expect(response.parsed_body.dig("data", "professional", "identity_verified")).to be(true)
    assert_api_conform(status: 200)
  end

  it "uses the same generic denial for malformed, unknown, revoked, and non-public bearers" do
    share_quote(request_id: "quote-share-for-denials", method: "copy")
    token = URI(response.parsed_body.dig("data", "share_url")).path.split("/").last
    draft = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Outro cliente",
          whatsapp_e164: "+5547999912042",
          email: nil
        },
        service_description: "Outro serviço",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    expect(draft).to be_draft
    denied_tokens = [
      "malformed",
      QuoteShareToken.issue,
      QuoteShareToken.issue
    ]
    envelopes = denied_tokens.map do |denied_token|
      resolve_quote(token: denied_token, request_id: "shared-quote-denied")
      expect(response).to have_http_status(:not_found)
      expect(response.headers.fetch("Cache-Control")).to eq("private, no-store")
      response.parsed_body
    end

    ProfessionalQuoteRevoker.new.call(quote: quote.reload)
    expect(Quote.find_by(share_token_hash: QuoteShareToken.digest(token))).to be_nil
    resolve_quote(token:, request_id: "shared-quote-denied")
    expect(response).to have_http_status(:not_found)
    envelopes << response.parsed_body

    share_quote(request_id: "quote-share-before-suspension", method: "copy")
    token = URI(response.parsed_body.dig("data", "share_url")).path.split("/").last
    profile.update!(profile_status: "suspended")
    resolve_quote(token:, request_id: "shared-quote-denied")
    expect(response).to have_http_status(:not_found)
    envelopes << response.parsed_body

    expect(envelopes.uniq).to eq([
      {
        "error" => {
          "code" => "not_found",
          "message" => "Orçamento não encontrado.",
          "request_id" => "shared-quote-denied"
        }
      }
    ])
    assert_api_conform(status: 404)
  end

  it "revokes a shared link so the customer's copy stops resolving" do
    share_quote(request_id: "quote-share-before-revoke", method: "copy")
    token = URI(response.parsed_body.dig("data", "share_url")).path.split("/").last

    revoke_share(request_id: "quote-share-revoke")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quote")).to include(
      "status" => "draft",
      "shared_at" => nil
    )
    expect(quote.reload).to have_attributes(
      status: "draft",
      share_token_hash: nil,
      share_token_ciphertext: nil,
      shared_at: nil
    )
    assert_api_conform(status: 200)

    resolve_quote(token:, request_id: "shared-quote-after-revoke")
    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Ana Paula")
    assert_api_conform(status: 404)

    revoke_share(request_id: "quote-share-revoke-twice")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "code")).to eq("quote_not_shared")
    assert_api_conform(status: 422)

    share_quote(request_id: "quote-share-after-revoke", method: "copy")
    new_token = URI(response.parsed_body.dig("data", "share_url")).path.split("/").last
    expect(new_token).not_to eq(token)
    resolve_quote(token: new_token, request_id: "shared-quote-new-link")
    expect(response).to have_http_status(:ok)
  end

  it "enforces owner, session, origin, publication, and safe unavailable responses" do
    own_quote = quote
    other_account = UserAccount.create!(
      phone_e164: "+5547999997442",
      role: "professional",
      status: "active"
    )
    other_profile = ProfessionalProfile.create!(user_account: other_account, display_name: "Beto Lima")
    other_quote = ProfessionalQuoteWriter.new.call(
      profile: other_profile,
      attributes: {
        customer: {
          id: nil,
          name: "Outro cliente",
          whatsapp_e164: "+5547999912043",
          email: nil
        },
        service_description: "Outro serviço",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )

    post "/api/v1/professional/quotes/#{own_quote.id}/share",
      params: {share: {method: "copy"}},
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "quote-share-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/quotes/#{own_quote.id}/share",
      params: {share: {method: "copy"}},
      headers: session_headers(request_id: "quote-share-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/quotes/#{other_quote.id}/share",
      params: {share: {method: "copy"}},
      headers: session_headers(request_id: "quote-share-owner", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    delete "/api/v1/professional/quotes/#{own_quote.id}/share",
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "quote-revoke-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/professional/quotes/#{own_quote.id}/share",
      headers: session_headers(request_id: "quote-revoke-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    delete "/api/v1/professional/quotes/#{other_quote.id}/share",
      headers: session_headers(request_id: "quote-revoke-owner", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    profile.update!(profile_status: "draft", published_revision: nil)
    share_quote(request_id: "quote-share-unpublished", method: "copy")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(own_quote.reload).to be_draft
    expect(own_quote.share_token_hash).to be_nil
    assert_api_conform(status: 422)

    post "/api/v1/shared-quotes/resolve",
      params: {token: "malformed"},
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "quote-resolve-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    allow(SharedQuoteResolver).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)
    resolve_quote(token: "malformed", request_id: "quote-resolve-unavailable")
    expect(response).to have_http_status(:service_unavailable)
    expect(response.headers.fetch("Cache-Control")).to eq("private, no-store")
    assert_api_conform(status: 503)
  end

  private

  def publish_profile!
    revision = profile.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    make_profile_publicly_eligible(profile, revision:)
  end

  def create_approved_identity!
    profile.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      public_label: ModerationDecision::IDENTITY_LABEL,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago,
      verified_at: 1.day.ago
    )
  end

  def create_approved_photo!
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 120,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 2.days.ago,
      processed_at: 2.days.ago,
      attached_at: 2.days.ago
    )
    profile.profile_photos.create!(
      media_upload: upload,
      status: "approved",
      private_key: upload.sanitized_key,
      public_key: "moderation/profile_photo/#{SecureRandom.uuid}.jpg",
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago
    )
  end

  def share_quote(request_id:, method:)
    post "/api/v1/professional/quotes/#{quote.id}/share",
      params: {share: {method:}},
      headers: session_headers(request_id:, origin: true),
      as: :json
  end

  def revoke_share(request_id:)
    delete "/api/v1/professional/quotes/#{quote.id}/share",
      headers: session_headers(request_id:, origin: true),
      as: :json
  end

  def resolve_quote(token:, request_id:)
    post "/api/v1/shared-quotes/resolve",
      params: {token:},
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id},
      as: :json
  end

  def session_headers(request_id:, origin: false)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session_token}"
    }
    headers["Origin"] = (origin == true) ? ENV.fetch("WEB_ORIGIN") : origin if origin
    headers
  end
end
