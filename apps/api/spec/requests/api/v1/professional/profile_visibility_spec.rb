# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional profile visibility", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998171", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Visibilidade")
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "moves a published profile between discoverable, direct-link, and unpublished access" do
    make_profile_publicly_eligible(profile)

    update_visibility("direct_link", request_id: "profile-visibility-direct")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile")).to include(
      "public_visibility" => "direct_link",
      "is_public" => true,
      "is_search_eligible" => false,
      "is_indexable" => false
    )
    expect(profile.reload.public_visibility).to eq("direct_link")
    assert_api_conform(status: 200)

    update_visibility("unpublished", request_id: "profile-visibility-unpublished")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile")).to include(
      "public_visibility" => "unpublished",
      "is_public" => false,
      "is_search_eligible" => false,
      "is_indexable" => false
    )
    assert_api_conform(status: 200)

    update_visibility("discoverable", request_id: "profile-visibility-discoverable")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile")).to include(
      "public_visibility" => "discoverable",
      "is_public" => true,
      "is_search_eligible" => true
    )
    assert_api_conform(status: 200)
  end

  it "rejects visibility changes until the profile is published" do
    update_visibility("unpublished", request_id: "profile-visibility-draft")

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("profile_not_published")
    expect(profile.reload.public_visibility).to eq("discoverable")
    assert_api_conform(status: 409)
  end

  it "returns field errors when the visibility update is rejected" do
    make_profile_publicly_eligible(profile)
    updater = instance_double(ProfessionalProfileVisibilityUpdater)
    allow(ProfessionalProfileVisibilityUpdater).to receive(:new).and_return(updater)
    allow(updater).to receive(:call).and_raise(
      ProfessionalProfileVisibilityUpdater::Invalid.new(
        visibility: ["selecione uma opção de visibilidade válida"]
      )
    )

    update_visibility("direct_link", request_id: "profile-visibility-invalid")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "visibility")).to be_present
    expect(profile.reload.public_visibility).to eq("discoverable")
    assert_api_conform(status: 422)
  end

  it "requires an authenticated owner and the exact browser origin" do
    make_profile_publicly_eligible(profile)

    patch "/api/v1/professional/profile/visibility",
      params: {profile_visibility: {visibility: "unpublished"}},
      headers: {"X-Request-Id" => "profile-visibility-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json

    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/profile/visibility",
      params: {profile_visibility: {visibility: "unpublished"}},
      headers: session_headers(
        request_id: "profile-visibility-origin",
        origin: "https://untrusted.example"
      ),
      as: :json

    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    account_without_profile = UserAccount.create!(
      phone_e164: "+5547999998172",
      role: "professional",
      status: "active"
    )
    token_without_profile = ApplicationSession.issue!(user_account: account_without_profile).last
    patch "/api/v1/professional/profile/visibility",
      params: {profile_visibility: {visibility: "unpublished"}},
      headers: session_headers(
        request_id: "profile-visibility-missing",
        origin: true,
        token: token_without_profile
      ),
      as: :json

    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def update_visibility(visibility, request_id:)
    patch "/api/v1/professional/profile/visibility",
      params: {profile_visibility: {visibility:}},
      headers: session_headers(request_id:, origin: true),
      as: :json
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
