# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator identity moderation", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "moderation-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999998205",
      role: "professional",
      status: "active",
      phone_verified_at: Time.current,
      registered_at: Time.current
    )
  end
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      birthdate: Date.new(1990, 4, 12)
    )
  end
  let(:request_record) { create_verification_request }

  it "lists only identity requests and approves one with an immutable audit action" do
    request_record

    get "/api/v1/admin/moderation",
      params: {status: "pending_review", page: 1, per_page: 20},
      headers: session_headers("moderation-list")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "items")).to contain_exactly(
      hash_including(
        "target_type" => "verification_request",
        "target_id" => request_record.id,
        "status" => "pending_review"
      )
    )
    assert_api_conform(status: 200)

    post "/api/v1/admin/moderation/verification_request/#{request_record.id}/decisions",
      params: {decision: {action: "approved", identity_match_confirmed: true}},
      headers: session_headers("moderation-approve", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(request_record.reload.status).to eq("approved")
    expect(ModerationAction.sole).to have_attributes(
      admin_user: admin,
      target_type: "verification_request",
      target_id: request_record.id,
      action: "approved"
    )
    assert_api_conform(status: 200)

    post "/api/v1/admin/moderation/verification_request/#{request_record.id}/decisions",
      params: {decision: {action: "approved", identity_match_confirmed: true}},
      headers: session_headers("moderation-conflict", origin: true),
      as: :json

    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)
  end

  it "rejects unsupported targets and invalid rejection reasons" do
    request_record

    post "/api/v1/admin/moderation/unsupported/#{profile.id}/decisions",
      params: {decision: {action: "approved", identity_match_confirmed: true}},
      headers: session_headers("moderation-target", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)

    post "/api/v1/admin/moderation/verification_request/#{request_record.id}/decisions",
      params: {decision: {action: "rejected", reason: "curto"}},
      headers: session_headers("moderation-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ModerationAction.count).to eq(0)
  end

  it "requires an administrator session" do
    get "/api/v1/admin/moderation", headers: {"X-Request-Id" => "moderation-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/admin/moderation/verification_request/#{request_record.id}/decisions",
      params: {decision: {action: "approved", identity_match_confirmed: true}},
      headers: {"X-Request-Id" => "moderation-decision-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/admin/moderation/verification_request/#{request_record.id}/decisions",
      params: {decision: {action: "approved", identity_match_confirmed: true}},
      headers: session_headers("moderation-decision-origin"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  private

  def session_headers(request_id, origin: false)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{admin_token}"
    }
    headers["Origin"] = ENV.fetch("WEB_ORIGIN") if origin
    headers
  end

  def create_verification_request
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "verification_identity",
      state: "attached",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    record = profile.verification_requests.create!(
      verification_type: "identity",
      status: "pending_review",
      claimed_birthdate: profile.birthdate,
      submitted_at: Time.current
    )
    record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 960,
      uploaded_at: Time.current
    )
    record
  end
end
