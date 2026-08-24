# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional registration", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  it "records legal acceptance, creates one draft profile, and becomes retry-safe" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = create_account(phone: "+5547999999001")
    _application_session, session_token = ApplicationSession.issue!(user_account: account, now:)

    complete_registration(
      session_token:,
      display_name: "  Ana   Souza  ",
      accepted: true,
      request_id: "registration-complete"
    )

    expect(response).to have_http_status(:ok)
    profile = account.reload.professional_profile
    expect(response.parsed_body).to eq(
      "data" => {
        "status" => "completed",
        "profile" => {
          "id" => profile.id,
          "display_name" => "Ana Souza",
          "profile_status" => "draft"
        }
      },
      "request_id" => "registration-complete"
    )
    expect(response.body).not_to include(account.phone_e164, "terms_version", "privacy_notice_version")
    expect(account.terms_accepted_at).to eq(now)
    expect(account.terms_version).to eq("1.0")
    expect(account.privacy_notice_version).to eq("1.0")
    expect(account.registered_at).to eq(now)
    expect(account).to be_registration_completed
    assert_api_conform(status: 200)

    restore_session(session_token:, request_id: "registration-session-after")
    expect(response.parsed_body.dig("data", "account", "registration_completed")).to be(true)
    complete_registration(
      session_token:,
      display_name: "Nome Diferente",
      accepted: true,
      request_id: "registration-retry"
    )

    expect(response).to have_http_status(:ok)
    expect(account.professional_profile.reload.display_name).to eq("Ana Souza")
    expect(ProfessionalProfile.where(user_account: account).count).to eq(1)
  end

  it "rejects an unaccepted legal notice with field-safe validation" do
    account = create_account(phone: "+5547999999002")
    _application_session, session_token = ApplicationSession.issue!(user_account: account)

    complete_registration(
      session_token:,
      display_name: "Ana Souza",
      accepted: false,
      request_id: "registration-invalid"
    )

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "validation_failed",
        "message" => "Revise os campos informados.",
        "request_id" => "registration-invalid",
        "field_errors" => {"accepted" => ["deve ser confirmado"]}
      }
    )
    expect(account.reload.professional_profile).to be_nil
    expect(account.terms_accepted_at).to be_nil
    assert_api_conform(status: 422)
  end

  it "rejects anonymous and suspended sessions generically" do
    complete_registration(
      session_token: nil,
      display_name: "Ana Souza",
      accepted: true,
      request_id: "registration-anonymous"
    )

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("authentication_required")
    assert_api_conform(status: 401)

    account = create_account(phone: "+5547999999003")
    _application_session, session_token = ApplicationSession.issue!(user_account: account)
    account.update!(status: "suspended")
    complete_registration(
      session_token:,
      display_name: "Ana Souza",
      accepted: true,
      request_id: "registration-suspended"
    )
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects invalid origins and active admin accounts without creating a professional profile" do
    professional = create_account(phone: "+5547999999004")
    _professional_session, professional_token = ApplicationSession.issue!(user_account: professional)
    complete_registration(
      session_token: professional_token,
      origin: "https://untrusted.example",
      display_name: "Ana Souza",
      accepted: true,
      request_id: "registration-origin-denied"
    )
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
    expect(professional.reload.professional_profile).to be_nil

    now = Time.current
    admin = create_account(phone: "+5547999999005", role: "admin")
    _admin_session, admin_token = ApplicationSession.issue!(user_account: admin, now:)
    complete_registration(
      session_token: admin_token,
      display_name: "Admin Berufe",
      accepted: true,
      request_id: "registration-admin-denied"
    )

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("authorization_denied")
    expect(admin.reload.professional_profile).to be_nil
    assert_api_conform(status: 403)
  end

  it "returns a safe unavailable response when registration persistence fails" do
    account = create_account(phone: "+5547999999006")
    _application_session, session_token = ApplicationSession.issue!(user_account: account)
    allow(ProfessionalRegistration).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    complete_registration(
      session_token:,
      display_name: "Ana Souza",
      accepted: true,
      request_id: "registration-unavailable"
    )

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "registration_unavailable",
        "message" => "Não foi possível concluir seu cadastro agora.",
        "request_id" => "registration-unavailable"
      }
    )
    assert_api_conform(status: 503)
  end

  private

  def create_account(phone:, role: "professional")
    if role == "admin"
      UserAccount.create!(
        email: "admin@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        role:,
        status: "active"
      )
    else
      UserAccount.create!(
        phone_e164: phone,
        role:,
        status: "active",
        phone_verified_at: Time.current
      )
    end
  end

  def restore_session(session_token:, request_id:)
    get "/api/v1/session", headers: session_headers(session_token:, request_id:)
  end

  def complete_registration(
    session_token:,
    display_name:,
    accepted:,
    request_id:,
    origin: ENV.fetch("WEB_ORIGIN")
  )
    headers = session_headers(session_token:, request_id:)
    headers["Origin"] = origin if origin
    put "/api/v1/professional-registration", params: {display_name:, accepted:}, headers:, as: :json
  end

  def session_headers(session_token:, request_id:)
    headers = {"X-Request-Id" => request_id}
    headers["Cookie"] = "#{ApplicationSession::COOKIE_NAME}=#{session_token}" if session_token
    headers
  end
end
