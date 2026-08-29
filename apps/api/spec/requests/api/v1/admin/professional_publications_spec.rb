# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator professional publication decisions", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "professional-publications-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }
  let(:account) { UserAccount.create!(phone_e164: "+5547999993001", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "unpublishes a live profile with a private reason and an immutable audit row" do
    make_profile_publicly_eligible(profile)

    post "/api/v1/admin/professionals/#{profile.id}/publication",
      params: {publication: {published: false, reason: "Denúncia de identidade falsa confirmada."}},
      headers: session_headers(admin_token, "professional-publication-hide", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(profile.reload.profile_status).to eq("suspended")
    expect(ModerationAction.sole).to have_attributes(
      admin_user: admin,
      target_type: "profile_revision",
      action: "hidden",
      reason: "Denúncia de identidade falsa confirmada.",
      request_id: "professional-publication-hide"
    )
    ids = response.parsed_body.dig("data", "items").pluck("id")
    expect(ids).to include(account.id)
    assert_api_conform(status: 200)
  end

  it "republishes a suspended profile" do
    make_profile_publicly_eligible(profile)
    profile.update!(profile_status: "suspended")

    post "/api/v1/admin/professionals/#{profile.id}/publication",
      params: {publication: {published: true}},
      headers: session_headers(admin_token, "professional-publication-restore", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(profile.reload.profile_status).to eq("published")
    expect(ModerationAction.sole).to have_attributes(action: "restored", reason: nil)
    assert_api_conform(status: 200)
  end

  it "returns the documented failures without appending audit rows" do
    post "/api/v1/admin/professionals/#{profile.id}/publication",
      params: {publication: {published: true}},
      headers: session_headers(admin_token, "professional-publication-conflict", origin: true),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    make_profile_publicly_eligible(profile)
    post "/api/v1/admin/professionals/#{profile.id}/publication",
      params: {publication: {published: false, reason: "curto"}},
      headers: session_headers(admin_token, "professional-publication-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    post "/api/v1/admin/professionals/00000000-0000-4000-8000-000000000001/publication",
      params: {publication: {published: true}},
      headers: session_headers(admin_token, "professional-publication-missing", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    expect(ModerationAction.count).to eq(0)
  end

  it "requires a trusted origin and a password-authenticated administrator" do
    make_profile_publicly_eligible(profile)

    post "/api/v1/admin/professionals/#{profile.id}/publication",
      params: {publication: {published: false, reason: "Motivo com detalhes suficientes para revisão."}},
      headers: session_headers(admin_token, "professional-publication-untrusted", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/admin/professionals/#{profile.id}/publication",
      params: {publication: {published: false, reason: "Motivo com detalhes suficientes para revisão."}},
      headers: {"X-Request-Id" => "professional-publication-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    expect(profile.reload.profile_status).to eq("published")
    expect(ModerationAction.count).to eq(0)
  end

  private

  def session_headers(token, request_id, origin: false)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
    headers["Origin"] = (origin == true) ? ENV.fetch("WEB_ORIGIN") : origin if origin
    headers
  end
end
