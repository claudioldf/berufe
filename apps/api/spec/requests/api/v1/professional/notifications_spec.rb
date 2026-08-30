# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional notifications", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { create_registered_account("+5547999973021") }
  let(:session_token) { ApplicationSession.issue!(user_account: account).last }

  it "returns unread activity newest first with an opaque stable cursor and exact count" do
    older = create_notification(account:, key: "older", occurred_at: 3.minutes.ago)
    middle = create_notification(account:, key: "middle", occurred_at: 2.minutes.ago)
    newer = create_notification(account:, key: "newer", occurred_at: 1.minute.ago)
    read = create_notification(account:, key: "read", occurred_at: Time.current)
    read.update!(status: "read", read_at: Time.current)

    get "/api/v1/professional/notifications",
      params: {limit: 2},
      headers: session_headers(request_id: "notifications-index")

    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.parsed_body.dig("data", "notifications").pluck("id")).to eq([newer.id, middle.id])
    expect(response.parsed_body.dig("data", "notifications").first).to include(
      "route" => "/app/professional/quotes/new?quote=#{newer.route_params.fetch("quote_id")}"
    )
    expect(response.body).not_to include("route_params")
    expect(response.parsed_body.dig("data", "unread_count")).to eq(3)
    cursor = response.parsed_body.dig("data", "next_cursor")
    expect(cursor).to be_present
    assert_api_conform(status: 200)

    get "/api/v1/professional/notifications",
      params: {limit: 2, cursor:},
      headers: session_headers(request_id: "notifications-next")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "notifications").pluck("id")).to eq([older.id])
    expect(response.parsed_body.dig("data", "unread_count")).to eq(3)
    expect(response.parsed_body.dig("data", "next_cursor")).to be_nil
    assert_api_conform(status: 200)
  end

  it "resolves a recommendation destination from the recipient's current profile slug" do
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Inicial")
    notification = Notification.create!(
      recipient_user_account: account,
      notification_type: "customer_recommendation_published",
      title: "Nova recomendação publicada",
      description: "Uma recomendação de cliente foi publicada no seu perfil.",
      route_params: {},
      idempotency_key: "recommendation:current-slug",
      occurred_at: Time.current
    )
    profile.update!(public_slug: "ana-atualizada")

    get "/api/v1/professional/notifications",
      headers: session_headers(request_id: "notification-current-slug")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "notifications").sole).to include(
      "id" => notification.id,
      "route" => "/profissionais/ana-atualizada#customer-recommendations-title"
    )
    expect(response.body).not_to include("route_params")
    assert_api_conform(status: 200)
  end

  it "rejects malformed pagination without leaking cursor details" do
    get "/api/v1/professional/notifications",
      params: {cursor: "tampered"},
      headers: session_headers(request_id: "notifications-invalid")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include("cursor")
    expect(response.body).not_to include("tampered")
    assert_api_conform(status: 422)
  end

  it "marks an owned notification read idempotently and hides other professionals' records" do
    notification = create_notification(account:, key: "owned", occurred_at: Time.current)
    other = create_registered_account("+5547999973022")
    hidden = create_notification(account: other, key: "other", occurred_at: Time.current)

    patch "/api/v1/professional/notifications/#{notification.id}/read",
      headers: session_headers(request_id: "notification-read", origin: true)

    expect(response).to have_http_status(:ok)
    first_read_at = notification.reload.read_at
    expect(response.parsed_body.dig("data", "notification", "status")).to eq("read")
    expect(response.parsed_body.dig("data", "unread_count")).to eq(0)
    assert_api_conform(status: 200)

    travel 1.minute do
      patch "/api/v1/professional/notifications/#{notification.id}/read",
        headers: session_headers(request_id: "notification-read-again", origin: true)
    end
    expect(response).to have_http_status(:ok)
    expect(notification.reload.read_at).to eq(first_read_at)
    assert_api_conform(status: 200)

    patch "/api/v1/professional/notifications/#{hidden.id}/read",
      headers: session_headers(request_id: "notification-other", origin: true)
    expect(response).to have_http_status(:not_found)
    expect(hidden.reload).to be_unread
    assert_api_conform(status: 404)
  end

  it "marks only unread records present at the read-all cutoff" do
    now = Time.zone.parse("2026-08-30 15:00:00 UTC")
    travel_to(now) do
      create_notification(account:, key: "present", occurred_at: now - 1.minute)
      create_notification(
        account:,
        key: "later",
        occurred_at: now + 1.minute,
        created_at: now + 1.minute
      )

      patch "/api/v1/professional/notifications/read-all",
        headers: session_headers(request_id: "notifications-read-all", origin: true)
    end

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data")).to eq(
      "marked_read_count" => 1,
      "unread_count" => 1
    )
    expect(Notification.find_by!(idempotency_key: "present")).to be_read
    expect(Notification.find_by!(idempotency_key: "later")).to be_unread
    assert_api_conform(status: 200)
  end

  it "requires an eligible session and exact origin for mutations" do
    get "/api/v1/professional/notifications",
      headers: {"X-Request-Id" => "notifications-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    unregistered = UserAccount.create!(
      phone_e164: "+5547999973023",
      role: "professional",
      status: "active"
    )
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    get "/api/v1/professional/notifications",
      headers: session_headers(
        request_id: "notifications-unregistered",
        token: unregistered_token
      )
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    notification = create_notification(account:, key: "origin", occurred_at: Time.current)
    patch "/api/v1/professional/notifications/#{notification.id}/read",
      headers: {
        "X-Request-Id" => "notification-read-anonymous",
        "Origin" => ENV.fetch("WEB_ORIGIN")
      }
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/notifications/#{notification.id}/read",
      headers: session_headers(
        request_id: "notification-origin",
        origin: "https://untrusted.example"
      )
    expect(response).to have_http_status(:forbidden)
    expect(notification.reload).to be_unread
    assert_api_conform(status: 403)

    patch "/api/v1/professional/notifications/read-all",
      headers: {
        "X-Request-Id" => "notifications-read-all-anonymous",
        "Origin" => ENV.fetch("WEB_ORIGIN")
      }
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/notifications/read-all",
      headers: session_headers(
        request_id: "notifications-read-all-origin",
        origin: "https://untrusted.example"
      )
    expect(response).to have_http_status(:forbidden)
    expect(notification.reload).to be_unread
    assert_api_conform(status: 403)
  end

  def create_registered_account(phone)
    UserAccount.create!(
      phone_e164: phone,
      role: "professional",
      status: "active",
      phone_verified_at: 2.minutes.ago,
      registered_at: 1.minute.ago,
      terms_accepted_at: 1.minute.ago,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
  end

  def create_notification(account:, key:, occurred_at:, created_at: Time.current)
    quote_id = SecureRandom.uuid
    Notification.create!(
      recipient_user_account: account,
      notification_type: "quote_approved",
      title: "Orçamento aprovado",
      description: "Um cliente aprovou um orçamento.",
      route_params: {quote_id:},
      idempotency_key: key,
      occurred_at:,
      created_at:,
      updated_at: created_at
    )
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
