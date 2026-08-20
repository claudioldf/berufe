# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional relationship requests", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:initiator_account) do
    UserAccount.create!(phone_e164: "+5547999981101", role: "professional", status: "active")
  end
  let(:initiator) do
    ProfessionalProfile.create!(user_account: initiator_account, display_name: "Ana Iniciadora")
  end
  let(:recipient) { create_published_profile("+5547999981102", "Beto Publicado") }
  let(:session_token) do
    initiator
    ApplicationSession.issue!(user_account: initiator_account).last
  end

  before do
    initiator.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      submitted_at: 1.day.ago,
      verified_at: Time.current
    )
  end

  it "creates a normalized private pending request and records meaningful activity" do
    post "/api/v1/professional/relationships",
      params: relationship_params(context_note: "  Executamos uma reforma juntos.  "),
      headers: session_headers(request_id: "relationship-create", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    relationship = ProfessionalRelationship.sole
    expect(response.headers["Location"]).to end_with(relationship.id)
    expect(response.parsed_body.dig("data", "relationship")).to include(
      "id" => relationship.id,
      "relationship_type" => "recommendation",
      "context_note" => "Executamos uma reforma juntos.",
      "status" => "pending",
      "responded_at" => nil,
      "recipient" => {
        "id" => recipient.id,
        "public_slug" => recipient.public_slug,
        "display_name" => "Beto Publicado"
      }
    )
    expect(response.body).not_to include(recipient.user_account.phone_e164)
    expect(ProfessionalDailyActivity.sole).to have_attributes(
      professional: initiator,
      relationship_interactions: 1
    )
    assert_api_conform(status: 201)
  end

  it "requires an approved identity and a currently published recipient" do
    initiator.verification_requests.update_all(status: "expired")

    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-unverified", origin: true),
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(ProfessionalRelationship.count).to eq(0)
    expect(ProfessionalDailyActivity.count).to eq(0)
    assert_api_conform(status: 403)

    initiator.verification_requests.update_all(status: "approved")
    recipient.update!(profile_status: "suspended")
    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-private-target", origin: true),
      as: :json

    expect(response).to have_http_status(:not_found)
    expect(ProfessionalRelationship.count).to eq(0)
    assert_api_conform(status: 404)
  end

  it "rejects self relationships and invalid public input without activity" do
    publish_profile!(initiator)

    post "/api/v1/professional/relationships",
      params: relationship_params(recipient_id: initiator.id),
      headers: session_headers(request_id: "relationship-self", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "recipient_professional_id")).to be_present
    assert_api_conform(status: 422)

    post "/api/v1/professional/relationships",
      params: relationship_params(relationship_type: "follow"),
      headers: session_headers(request_id: "relationship-type", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ProfessionalRelationship.count).to eq(0)
    expect(ProfessionalDailyActivity.count).to eq(0)
  end

  it "returns conflict for an exact directional duplicate while preserving the first activity" do
    ProfessionalRelationshipRequester.new.call(
      initiator:,
      recipient_professional_id: recipient.id,
      relationship_type: "recommendation",
      context_note: nil
    )

    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-duplicate", origin: true),
      as: :json

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("relationship_conflict")
    expect(ProfessionalRelationship.count).to eq(1)
    expect(ProfessionalDailyActivity.sole.relationship_interactions).to eq(1)
    assert_api_conform(status: 409)
  end

  it "denies anonymous and invalid-origin mutations" do
    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: {"X-Request-Id" => "relationship-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  it "lets only the recipient accept once and records the response activity" do
    relationship = create_pending_relationship
    publish_profile!(initiator)
    now = Time.zone.parse("2026-08-18 14:30:00 UTC")
    travel_to(now) do
      post "/api/v1/professional/relationships/#{relationship.id}/response",
        params: {response: "accepted"},
        headers: session_headers(
          request_id: "relationship-accept",
          origin: true,
          token: recipient_session_token
        ),
        as: :json
    end

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "relationship")).to include(
      "id" => relationship.id,
      "status" => "accepted",
      "responded_at" => now.iso8601(3)
    )
    expect(relationship.reload).to have_attributes(status: "accepted", responded_at: now)
    expect(PublicProfessionalRelationshipQuery.for_professional(recipient.id)).to contain_exactly(relationship)
    expect(ModerationAction.where(target_type: "professional_relationship")).to be_empty
    expect(
      ProfessionalDailyActivity.find_by!(professional: recipient).relationship_interactions
    ).to eq(1)
    assert_api_conform(status: 200)

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "declined"},
      headers: session_headers(
        request_id: "relationship-repeat",
        origin: true,
        token: recipient_session_token
      ),
      as: :json

    expect(response).to have_http_status(:conflict)
    expect(relationship.reload).to have_attributes(status: "accepted", responded_at: now)
    expect(
      ProfessionalDailyActivity.find_by!(professional: recipient).relationship_interactions
    ).to eq(1)
    assert_api_conform(status: 409)
  end

  it "lets the recipient decline while keeping the relationship private" do
    relationship = create_pending_relationship(relationship_type: "worked_together")

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "declined"},
      headers: session_headers(
        request_id: "relationship-decline",
        origin: true,
        token: recipient_session_token
      ),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(relationship.reload.status).to eq("declined")
    expect(PublicProfessionalRelationshipQuery.for_professional(recipient.id)).to be_empty
    assert_api_conform(status: 200)
  end

  it "does not let the initiator or an anonymous session respond" do
    relationship = create_pending_relationship

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "accepted"},
      headers: session_headers(request_id: "relationship-wrong-owner", origin: true),
      as: :json

    expect(response).to have_http_status(:not_found)
    expect(relationship.reload.status).to eq("pending")
    assert_api_conform(status: 404)

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "accepted"},
      headers: {"X-Request-Id" => "relationship-response-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json

    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  it "rejects a response from an invalid origin" do
    relationship = create_pending_relationship

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "accepted"},
      headers: session_headers(
        request_id: "relationship-response-origin",
        origin: "https://untrusted.example",
        token: recipient_session_token
      ),
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(relationship.reload.status).to eq("pending")
    assert_api_conform(status: 403)
  end

  private

  def relationship_params(
    recipient_id: recipient.id,
    relationship_type: "recommendation",
    context_note: nil
  )
    {
      relationship: {
        recipient_professional_id: recipient_id,
        relationship_type:,
        context_note:
      }
    }
  end

  def create_published_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name)
    publish_profile!(profile)
  end

  def create_pending_relationship(relationship_type: "recommendation")
    ProfessionalRelationship.create!(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type:,
      context_note: "Executamos uma reforma juntos."
    )
  end

  def recipient_session_token
    @recipient_session_token ||= ApplicationSession.issue!(user_account: recipient.user_account).last
  end

  def publish_profile!(profile)
    make_profile_publicly_eligible(profile)
  end

  def session_headers(request_id:, origin: false, token: session_token)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
    headers["Origin"] = (origin == true) ? ENV.fetch("WEB_ORIGIN") : origin if origin
    headers
  end
end
