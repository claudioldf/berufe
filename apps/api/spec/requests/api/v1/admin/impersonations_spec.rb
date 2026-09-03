# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator professional impersonation", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "impersonation-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) do
    session, token = ApplicationSession.issue!(user_account: admin)
    @admin_session = session
    token
  end
  let(:professional) { create_registered_professional }

  it "switches the effective account without creating a professional login and restores the admin" do
    original_login_count = professional.login_count
    original_last_login_at = professional.last_login_at

    post "/api/v1/admin/impersonation",
      params: {professional_account_id: professional.id},
      headers: session_headers(admin_token, "impersonation-start", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "account")).to include(
      "id" => professional.id,
      "role" => "professional",
      "registration_completed" => true,
      "registration_display_name" => "Ana Souza"
    )
    expect(response.parsed_body.dig("data", "session")).to include(
      "authentication_method" => "password",
      "impersonating" => true,
      "idle_expires_at" => @admin_session.idle_expires_at.iso8601(3),
      "absolute_expires_at" => @admin_session.absolute_expires_at.iso8601(3)
    )
    expect(@admin_session.reload.impersonated_user_account).to eq(professional)
    expect(professional.reload).to have_attributes(
      login_count: original_login_count,
      last_login_at: original_last_login_at
    )
    assert_api_conform(status: 200)

    delete "/api/v1/admin/impersonation",
      headers: session_headers(admin_token, "impersonation-stop", origin: true)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "account")).to include("id" => admin.id, "role" => "admin")
    expect(response.parsed_body.dig("data", "session", "impersonating")).to be(false)
    expect(@admin_session.reload.impersonated_user_account).to be_nil
    assert_api_conform(status: 200)

    delete "/api/v1/admin/impersonation",
      headers: session_headers(admin_token, "impersonation-stop-idempotent", origin: true)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "session", "impersonating")).to be(false)
  end

  it "authorizes reads and writes only against the selected professional" do
    other = create_registered_professional(phone: "+5547999997312", display_name: "Outra Pessoa")
    start_impersonating(professional)

    get "/api/v1/professional/workspace",
      headers: session_headers(admin_token, "impersonation-workspace")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "id")).to eq(professional.professional_profile.id)

    patch "/api/v1/professional/profile",
      params: {
        identity: {
          display_name: "Ana Administrada",
          birthdate: "1990-04-12",
          headline: "Atendimento profissional.",
          bio: "Serviços realizados em Joinville.",
          whatsapp: professional.phone_e164,
          instagram: "",
          youtube: ""
        }
      },
      headers: session_headers(admin_token, "impersonation-update", origin: true),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(professional.professional_profile.reload.display_name).to eq("Ana Administrada")
    expect(other.professional_profile.reload.display_name).to eq("Outra Pessoa")
  end

  it "blocks admin, registration, and erasure actions while impersonating" do
    start_impersonating(professional)

    get "/api/v1/admin/professionals",
      headers: session_headers(admin_token, "impersonation-admin-denied")
    expect(response).to have_http_status(:forbidden)

    get "/api/v1/admin/reports/growth",
      headers: session_headers(admin_token, "impersonation-reports-denied")
    expect(response).to have_http_status(:forbidden)

    get "/api/v1/admin/search-audits",
      headers: session_headers(admin_token, "impersonation-search-audits-denied")
    expect(response).to have_http_status(:forbidden)

    get "/api/v1/admin/catalog",
      headers: session_headers(admin_token, "impersonation-catalog-denied")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    get "/api/v1/admin/moderation",
      headers: session_headers(admin_token, "impersonation-moderation-denied")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    get "/api/v1/admin/verification-files/#{SecureRandom.uuid}/content",
      headers: session_headers(admin_token, "impersonation-verification-file-denied")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    put "/api/v1/professional-registration",
      params: {display_name: "Nome", accepted: true},
      headers: session_headers(admin_token, "impersonation-registration-denied", origin: true),
      as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("impersonation_action_denied")

    post "/api/v1/professional/media-uploads",
      params: {purpose: "verification_identity", content_type: "image/jpeg", byte_size: 1024},
      headers: session_headers(admin_token, "impersonation-verification-upload-denied", origin: true),
      as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("impersonation_action_denied")

    post "/api/v1/professional/verification-requests",
      params: {verification_request: {media_upload_id: SecureRandom.uuid, verification_type: "identity"}},
      headers: session_headers(admin_token, "impersonation-verification-request-denied", origin: true),
      as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("impersonation_action_denied")

    identity_upload = create_media_upload(purpose: "verification_identity")
    get "/api/v1/professional/media-uploads/#{identity_upload.id}",
      headers: session_headers(admin_token, "impersonation-verification-upload-show-denied")
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("impersonation_action_denied")

    photo_upload = create_media_upload(purpose: "profile_photo")
    get "/api/v1/professional/media-uploads/#{photo_upload.id}",
      headers: session_headers(admin_token, "impersonation-profile-photo-upload-show-allowed")
    expect(response).to have_http_status(:ok)

    post "/api/v1/professional/data-erasure-request",
      headers: session_headers(admin_token, "impersonation-erasure-denied", origin: true)
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("impersonation_action_denied")
  end

  it "rejects anonymous, professional, unknown, incomplete, stale, suspended, and nested attempts" do
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: professional.id},
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "impersonation-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)

    professional_token = ApplicationSession.issue!(user_account: professional).last
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: professional.id},
      headers: session_headers(professional_token, "impersonation-professional", origin: true),
      as: :json
    expect(response).to have_http_status(:unauthorized)

    unknown_id = SecureRandom.uuid
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: unknown_id},
      headers: session_headers(admin_token, "impersonation-unknown", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)

    incomplete = UserAccount.create!(phone_e164: "+5547999997313", role: "professional", status: "active")
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: incomplete.id},
      headers: session_headers(admin_token, "impersonation-incomplete", origin: true),
      as: :json
    expect(response).to have_http_status(:conflict)

    stale_acceptance = create_registered_professional(phone: "+5547999997316", display_name: "Aceite antigo")
    stale_acceptance.update_columns(terms_version: "obsolete")
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: stale_acceptance.id},
      headers: session_headers(admin_token, "impersonation-stale-acceptance", origin: true),
      as: :json
    expect(response).to have_http_status(:conflict)

    suspended = create_registered_professional(phone: "+5547999997314", display_name: "Suspensa")
    suspended.update_columns(status: "suspended")
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: suspended.id},
      headers: session_headers(admin_token, "impersonation-suspended", origin: true),
      as: :json
    expect(response).to have_http_status(:conflict)

    start_impersonating(professional)
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: professional.id},
      headers: session_headers(admin_token, "impersonation-nested", origin: true),
      as: :json
    expect(response).to have_http_status(:conflict)
  end

  it "enforces the origin, authentication, and payload boundaries on both transitions" do
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: professional.id},
      headers: session_headers(admin_token, "impersonation-invalid-origin"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/admin/impersonation",
      params: {},
      headers: session_headers(admin_token, "impersonation-missing-account", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    delete "/api/v1/admin/impersonation",
      headers: {
        "Origin" => ENV.fetch("WEB_ORIGIN"),
        "X-Request-Id" => "impersonation-stop-anonymous"
      }
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/admin/impersonation",
      headers: session_headers(admin_token, "impersonation-stop-invalid-origin")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    service = instance_double(::Admin::ProfessionalImpersonation)
    allow(::Admin::ProfessionalImpersonation).to receive(:new).and_return(service)
    allow(service).to receive(:start!).and_raise(
      ActionController::ParameterMissing.new(:professional_account_id)
    )
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: professional.id},
      headers: session_headers(admin_token, "impersonation-validation-response", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
  end

  it "clears an impersonation whose target becomes ineligible" do
    start_impersonating(professional)
    professional.update_columns(status: "suspended")

    get "/api/v1/session", headers: session_headers(admin_token, "impersonation-invalidated")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "account")).to include("id" => admin.id, "role" => "admin")
    expect(response.parsed_body.dig("data", "session", "impersonating")).to be(false)
    expect(@admin_session.reload.impersonated_user_account).to be_nil
  end

  it "revokes the underlying administrator session when logging out while impersonating" do
    start_impersonating(professional)

    delete "/api/v1/session",
      headers: session_headers(admin_token, "impersonation-logout", origin: true)

    expect(response).to have_http_status(:no_content)
    expect(@admin_session.reload.revoked_at).to be_present
    expect(response.headers.fetch("Set-Cookie")).to include("__Host-berufe_session=")
  end

  private

  def create_registered_professional(phone: "+5547999997311", display_name: "Ana Souza")
    account = UserAccount.create!(
      phone_e164: phone,
      phone_verified_at: Time.current,
      role: "professional",
      status: "active"
    )
    ProfessionalProfile.create!(user_account: account, display_name:)
    account.update!(
      registered_at: Time.current,
      terms_accepted_at: Time.current,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
    account
  end

  def create_media_upload(purpose:)
    MediaUpload.create!(
      professional_profile: professional.professional_profile,
      purpose:,
      state: "authorized",
      declared_content_type: "image/jpeg",
      declared_byte_size: 1024,
      quarantine_key: "quarantine/#{professional.professional_profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 5.minutes.from_now
    )
  end

  def start_impersonating(account)
    post "/api/v1/admin/impersonation",
      params: {professional_account_id: account.id},
      headers: session_headers(admin_token, "impersonation-setup", origin: true),
      as: :json
    expect(response).to have_http_status(:ok)
  end

  def session_headers(token, request_id, origin: false)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}",
      **({"Origin" => ENV.fetch("WEB_ORIGIN")} if origin)
    }
  end
end
