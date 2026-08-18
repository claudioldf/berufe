# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator professional-supply moderation", type: :request, openapi: true do
  let(:admin) { create_admin }
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }
  let(:profile) { create_profile }
  let(:service) { create_selected_service }
  let(:revision) do
    profile.working_revision.tap do |record|
      record.update!(status: "pending_review", submitted_at: 4.hours.ago)
    end
  end
  let(:photo) { create_photo(submitted_at: 3.hours.ago) }
  let(:portfolio_item) { create_portfolio_item(submitted_at: 2.hours.ago) }
  let(:verification_request) { create_verification_request(submitted_at: 1.hour.ago) }

  before do
    revision
    photo
    portfolio_item
    verification_request
  end

  it "returns the filtered, paginated oldest-first queue and safe summary" do
    get "/api/v1/admin/moderation",
      params: {type: "all", status: "pending_review", page: 1, per_page: 2},
      headers: session_headers(token: admin_token, request_id: "moderation-list")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body.dig("data", "items").pluck("target_id")).to eq([revision.id, photo.id])
    expect(response.parsed_body.dig("data", "meta")).to eq(
      "page" => 1,
      "per_page" => 2,
      "total_count" => 4,
      "total_pages" => 2
    )
    expect(response.parsed_body.dig("data", "summary", "pending_count")).to eq(4)
    expect(response.body).not_to include("private_key", "public_key", "sanitized/")
    assert_api_conform(status: 200)
  end

  it "validates queue filters" do
    query = instance_double(ModerationQueueQuery)
    allow(ModerationQueueQuery).to receive(:new).and_return(query)
    allow(query).to receive(:call).and_raise(
      ModerationQueueQuery::Invalid.new(type: ["use um tipo de moderação válido"])
    )
    get "/api/v1/admin/moderation",
      params: {type: "all", status: "pending_review", page: 1, per_page: 20},
      headers: session_headers(token: admin_token, request_id: "moderation-list-invalid")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors").keys).to contain_exactly("type")
    assert_api_conform(status: 422)
  end

  it "commits decisions with their immutable actor and private guidance" do
    post decision_path(revision),
      params: {decision: {action: "rejected", reason: "O texto profissional precisa de mais detalhes."}},
      headers: session_headers(token: admin_token, request_id: "moderation-reject", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(revision.reload).to have_attributes(
      status: "rejected",
      rejection_reason: "O texto profissional precisa de mais detalhes."
    )
    expect(ModerationAction.sole).to have_attributes(
      admin_user: admin,
      target_type: "profile_revision",
      target_id: revision.id,
      action: "rejected",
      reason: "O texto profissional precisa de mais detalhes.",
      request_id: "moderation-reject"
    )
    assert_api_conform(status: 200)
  end

  it "reviews accepted professional relationships through the shared queue" do
    partner_account = UserAccount.create!(
      phone_e164: "+5547999998206",
      role: "professional",
      status: "active"
    )
    partner = ProfessionalProfile.create!(user_account: partner_account, display_name: "Beto Lima")
    relationship = ProfessionalRelationship.create!(
      initiator_professional: partner,
      recipient_professional: profile,
      relationship_type: "recommendation",
      context_note: "Indicação confirmada entre membros.",
      status: "accepted",
      responded_at: 30.minutes.ago
    )

    get "/api/v1/admin/moderation",
      params: {type: "professional_relationship", status: "pending_review", page: 1, per_page: 20},
      headers: session_headers(token: admin_token, request_id: "relationship-moderation-list")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "items").sole).to include(
      "target_type" => "professional_relationship",
      "target_id" => relationship.id,
      "status" => "pending_review",
      "has_media" => false
    )
    assert_api_conform(status: 200)

    post "/api/v1/admin/moderation/professional_relationship/#{relationship.id}/decisions" \
      "?type=professional_relationship&status=pending_review&page=1&per_page=20",
      params: {decision: {action: "approved"}},
      headers: session_headers(token: admin_token, request_id: "relationship-moderation-approve", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(relationship.reload.status).to eq("accepted")
    expect(ModerationAction.where(target_type: "professional_relationship").sole).to have_attributes(
      action: "approved",
      target_id: relationship.id,
      admin_user: admin
    )
    expect(response.parsed_body.dig("data", "items")).to be_empty
    assert_api_conform(status: 200)
  end

  it "returns the documented decision failures without appending audit rows" do
    post decision_path(revision),
      params: {decision: {action: "approved"}},
      headers: session_headers(token: admin_token, request_id: "moderation-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/admin/moderation/profile_revision/00000000-0000-4000-8000-000000000001/decisions",
      params: {decision: {action: "approved"}},
      headers: session_headers(token: admin_token, request_id: "moderation-missing", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    revision.update!(status: "approved", reviewed_at: Time.current)
    post decision_path(revision),
      params: {decision: {action: "approved"}},
      headers: session_headers(token: admin_token, request_id: "moderation-stale", origin: true),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    revision.update!(status: "pending_review", reviewed_at: nil)
    post decision_path(revision),
      params: {decision: {action: "rejected", reason: "curto"}},
      headers: session_headers(token: admin_token, request_id: "moderation-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    expect(ModerationAction.count).to eq(0)
  end

  it "streams regenerated image bytes into the existing preview and records access" do
    storage = instance_double(LocalDiskStorage)
    allow(MediaStorage).to receive(:build).and_return(storage)
    allow(storage).to receive(:read).with(scope: :private, key: photo.private_key).and_return("regenerated-image")

    get media_path(photo), headers: session_headers(token: admin_token, request_id: "moderation-media")

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("regenerated-image")
    expect(response.media_type).to eq("image/jpeg")
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    expect(response.headers.fetch("Content-Disposition")).to start_with(
      "inline; filename=\"berufe-analise-profile_photo-#{photo.id}.jpg\""
    )
    expect(ModerationMediaAccessEvent.sole).to have_attributes(
      admin_user: admin,
      target_type: "profile_photo",
      target_id: photo.id,
      request_id: "moderation-media"
    )
    assert_api_conform(status: 200)

    allow(storage).to receive(:read).with(scope: :private, key: portfolio_item.private_key).and_return("regenerated-png")
    get "/api/v1/admin/moderation/portfolio_item/#{portfolio_item.id}/media",
      headers: session_headers(token: admin_token, request_id: "moderation-media-png")

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("regenerated-png")
    expect(response.media_type).to eq("image/png")
    expect(ModerationMediaAccessEvent.order(:created_at).last).to have_attributes(
      admin_user: admin,
      target_type: "portfolio_item",
      target_id: portfolio_item.id,
      request_id: "moderation-media-png"
    )
    assert_api_conform(status: 200)
  end

  it "does not expose missing or unsupported private media" do
    get "/api/v1/admin/moderation/profile_photo/00000000-0000-4000-8000-000000000001/media",
      headers: session_headers(token: admin_token, request_id: "moderation-media-missing")

    expect(response).to have_http_status(:not_found)
    expect(ModerationMediaAccessEvent.count).to eq(0)
    assert_api_conform(status: 404)
  end

  it "requires a password-authenticated administrator for every moderation operation" do
    get "/api/v1/admin/moderation", headers: {"X-Request-Id" => "moderation-anonymous-list"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post decision_path(revision),
      params: {decision: {action: "approved"}},
      headers: {"X-Request-Id" => "moderation-anonymous-decision", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get media_path(photo), headers: {"X-Request-Id" => "moderation-anonymous-media"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  private

  def decision_path(target)
    "/api/v1/admin/moderation/profile_revision/#{target.id}/decisions"
  end

  def media_path(target)
    "/api/v1/admin/moderation/profile_photo/#{target.id}/media"
  end

  def session_headers(token:, request_id:, origin: false)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
    headers["Origin"] = (origin == true) ? ENV.fetch("WEB_ORIGIN") : origin if origin
    headers
  end

  def create_admin
    UserAccount.create!(
      email: "moderation-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end

  def create_profile
    account = UserAccount.create!(phone_e164: "+5547999998205", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  def create_selected_service
    category = ServiceCategory.create!(
      name: "Moderação Request",
      slug: "moderacao-request",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    created = Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista-moderacao-request",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    ProfessionalProfileService.create!(
      professional_profile_revision: profile.working_revision,
      service: created,
      is_primary: true
    )
    ProfessionalProfileServiceArea.create!(
      professional_profile_revision: profile.working_revision,
      neighborhood_code: nil
    )
    created
  end

  def create_upload(purpose:, content_type: "image/png")
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "processed",
      declared_content_type: content_type,
      declared_byte_size: 120,
      actual_content_type: content_type,
      sanitized_content_type: content_type,
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.#{(content_type == "image/png") ? "png" : "jpg"}",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
  end

  def create_photo(submitted_at:)
    upload = create_upload(purpose: "profile_photo", content_type: "image/jpeg")
    profile.profile_photos.create!(
      media_upload: upload,
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at:
    )
  end

  def create_portfolio_item(submitted_at:)
    upload = create_upload(purpose: "portfolio_image")
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title: "Cozinha iluminada",
      description: "Instalação completa.",
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at:
    )
  end

  def create_verification_request(submitted_at:)
    upload = create_upload(purpose: "verification_identity")
    record = profile.verification_requests.create!(
      verification_type: "identity",
      status: "pending_review",
      submitted_at:
    )
    record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 960,
      uploaded_at: submitted_at
    )
    record
  end
end
