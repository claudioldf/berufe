# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional relationship candidates", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999981301",
      role: "professional",
      status: "active",
      phone_verified_at: Time.current,
      registered_at: Time.current,
      terms_accepted_at: Time.current,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
  end
  let(:initiator) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana da Busca")
  end
  let(:session_token) do
    initiator
    ApplicationSession.issue!(user_account: account).last
  end

  before do
    initiator.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      submitted_at: 1.day.ago,
      verified_at: Time.current
    )
  end

  it "finds public self-service and external profiles by name without exposing their phones" do
    self_service = create_public_profile("+5547999981302", "Carla Eletricista")
    relationship = ProfessionalRelationshipRequester.new.call(
      initiator:,
      target: {
        type: "phone",
        name: "Carla Pinturas",
        phone: "(47) 99998-1303",
        service_ids: [],
        coverage: {city_code: nil, whole_city: false, neighborhood_codes: []},
        contact_publication_attested: true
      },
      relationship_type: "recommendation",
      context_note: nil
    )
    external = relationship.recipient_professional

    get "/api/v1/professional/relationship-candidates",
      params: {query: "  carla  "},
      headers: session_headers(request_id: "relationship-candidates")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body.dig("data", "candidates")).to contain_exactly(
      {
        "id" => self_service.id,
        "public_slug" => self_service.public_slug,
        "display_name" => "Carla Eletricista",
        "profile_type" => "self_service",
        "photo_url" => a_string_including("/api/v1/public/profile-photos/")
      },
      {
        "id" => external.id,
        "public_slug" => external.public_slug,
        "display_name" => "Carla Pinturas",
        "profile_type" => "external",
        "photo_url" => nil
      }
    )
    expect(response.body).not_to include(
      self_service.user_account.phone_e164,
      external.user_account.phone_e164,
      initiator.id
    )
    assert_api_conform(status: 200)
  end

  it "returns no candidates below the minimum query length and validates the maximum" do
    get "/api/v1/professional/relationship-candidates",
      params: {query: "a"},
      headers: session_headers(request_id: "relationship-candidates-short")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "candidates")).to eq([])

    get "/api/v1/professional/relationship-candidates",
      params: {query: "a" * 71},
      headers: session_headers(request_id: "relationship-candidates-long")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "query")).to be_present
    assert_api_conform(status: 422)
  end

  it "requires an authenticated professional session" do
    get "/api/v1/professional/relationship-candidates",
      params: {query: "Carla"},
      headers: {"X-Request-Id" => "relationship-candidates-anonymous"}

    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  private

  def create_public_profile(phone, name)
    target_account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    make_profile_publicly_eligible(
      ProfessionalProfile.create!(user_account: target_account, display_name: name)
    )
  end

  def session_headers(request_id:)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session_token}"
    }
  end
end
