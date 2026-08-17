# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe "Professional private media uploads", type: :request, openapi: true do
  include ActiveJob::TestHelper

  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998161", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end
  let(:root) { Dir.mktmpdir("berufe-media-request") }
  let(:storage) { LocalDiskStorage.new(root:) }
  let(:jpeg) { Vips::Image.black(10, 6).jpegsave_buffer }
  let(:png) { Vips::Image.black(7, 5).pngsave_buffer }

  before { allow(MediaStorage).to receive(:build).and_return(storage) }

  after do
    clear_enqueued_jobs
    FileUtils.remove_entry(root) if File.exist?(root)
  end

  it "authorizes, receives, completes, and reports one owned private upload" do
    post "/api/v1/professional/media-uploads",
      params: {
        purpose: "profile_photo",
        content_type: "image/jpeg",
        byte_size: jpeg.bytesize
      },
      headers: session_headers(request_id: "media-authorize", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    upload_id = response.parsed_body.dig("data", "media_upload", "id")
    expect(response.parsed_body.dig("data", "upload")).to include(
      "strategy" => "rails",
      "method" => "PUT",
      "headers" => {"Content-Type" => "image/jpeg"}
    )
    expect(response.parsed_body.dig("data", "upload", "url")).to end_with(
      "/media-uploads/#{upload_id}/content"
    )
    expect(response.headers["Cache-Control"]).to include("no-store")
    assert_api_conform(status: 201)

    put "/api/v1/professional/media-uploads/#{upload_id}/content",
      params: jpeg,
      headers: session_headers(request_id: "media-content", origin: true).merge(
        "CONTENT_TYPE" => "image/jpeg"
      )

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "media_upload", "state")).to eq("uploaded")
    assert_api_conform(status: 200)

    expect do
      post "/api/v1/professional/media-uploads/#{upload_id}/completion",
        headers: session_headers(request_id: "media-completion", origin: true)
    end.to have_enqueued_job(MediaUploadProcessingJob).with(upload_id)
    expect(response).to have_http_status(:accepted)
    assert_api_conform(status: 202)

    get "/api/v1/professional/media-uploads/#{upload_id}",
      headers: session_headers(request_id: "media-show")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "media_upload")).to include(
      "id" => upload_id,
      "purpose" => "profile_photo",
      "retryable" => false
    )
    assert_api_conform(status: 200)
  end

  it "rejects unsupported declarations and repeated content writes" do
    post "/api/v1/professional/media-uploads",
      params: {purpose: "profile_photo", content_type: "image/svg+xml", byte_size: 10},
      headers: session_headers(request_id: "media-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "content_type")).to be_present

    mismatched = create_upload(byte_size: jpeg.bytesize + 1)
    put "/api/v1/professional/media-uploads/#{mismatched.id}/content",
      params: jpeg,
      headers: session_headers(request_id: "media-mismatch", origin: true).merge(
        "CONTENT_TYPE" => "image/jpeg"
      )
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "code")).to eq("byte_size_mismatch")
    assert_api_conform(status: 422)

    upload = create_upload(byte_size: jpeg.bytesize)
    MediaUploadReceiver.new.call(upload:, body: jpeg, content_type: "image/jpeg", storage:)
    put "/api/v1/professional/media-uploads/#{upload.id}/content",
      params: jpeg,
      headers: session_headers(request_id: "media-conflict", origin: true).merge(
        "CONTENT_TYPE" => "image/jpeg"
      )
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("upload_not_authorized")
    assert_api_conform(status: 409)
  end

  it "requires a valid session, exact origin, registration, and ownership" do
    post "/api/v1/professional/media-uploads",
      params: {purpose: "profile_photo", content_type: "image/jpeg", byte_size: 10},
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "media-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/media-uploads",
      params: {purpose: "profile_photo", content_type: "image/jpeg", byte_size: 10},
      headers: session_headers(request_id: "media-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    other = UserAccount.create!(phone_e164: "+5547999998162", role: "professional", status: "active")
    other_profile = ProfessionalProfile.create!(user_account: other, display_name: "Bia Lima")
    other_upload = MediaUpload.create!(
      professional_profile: other_profile,
      purpose: "portfolio_image",
      declared_content_type: "image/png",
      declared_byte_size: 10,
      quarantine_key: "quarantine/#{other_profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 10.minutes.from_now
    )
    get "/api/v1/professional/media-uploads/#{other_upload.id}",
      headers: session_headers(request_id: "media-other")
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "contracts authorization and status failures without disclosing storage details" do
    unregistered = UserAccount.create!(
      phone_e164: "+5547999998163",
      role: "professional",
      status: "active"
    )
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    post "/api/v1/professional/media-uploads",
      params: {purpose: "profile_photo", content_type: "image/jpeg", byte_size: 10},
      headers: session_headers(
        request_id: "media-unregistered",
        origin: true,
        token: unregistered_token
      ),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    authorizer = instance_double(MediaUploadAuthorizer)
    allow(MediaUploadAuthorizer).to receive(:new).and_return(authorizer)
    allow(authorizer).to receive(:call).and_raise(MediaUploadAuthorizer::Unavailable, "private detail")
    post "/api/v1/professional/media-uploads",
      params: {purpose: "profile_photo", content_type: "image/jpeg", byte_size: 10},
      headers: session_headers(request_id: "media-authorize-down", origin: true),
      as: :json
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "message")).not_to include("private detail")
    assert_api_conform(status: 503)

    get "/api/v1/professional/media-uploads/#{SecureRandom.uuid}",
      headers: {"X-Request-Id" => "media-show-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  it "contracts both local image formats and every content-upload boundary response" do
    png_upload = create_upload(byte_size: png.bytesize, content_type: "image/png")
    put "/api/v1/professional/media-uploads/#{png_upload.id}/content",
      params: png,
      headers: session_headers(request_id: "media-png", origin: true).merge(
        "CONTENT_TYPE" => "image/png"
      )
    expect(response).to have_http_status(:ok)
    assert_api_conform(status: 200)

    upload = create_upload(byte_size: jpeg.bytesize)
    put "/api/v1/professional/media-uploads/#{upload.id}/content",
      params: jpeg,
      headers: {
        "Origin" => ENV.fetch("WEB_ORIGIN"),
        "X-Request-Id" => "media-content-anonymous",
        "CONTENT_TYPE" => "image/jpeg"
      }
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    put "/api/v1/professional/media-uploads/#{upload.id}/content",
      params: jpeg,
      headers: session_headers(
        request_id: "media-content-origin",
        origin: "https://untrusted.example"
      ).merge("CONTENT_TYPE" => "image/jpeg")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    put "/api/v1/professional/media-uploads/#{SecureRandom.uuid}/content",
      params: jpeg,
      headers: session_headers(request_id: "media-content-missing", origin: true).merge(
        "CONTENT_TYPE" => "image/jpeg"
      )
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    receiver = instance_double(MediaUploadReceiver)
    allow(MediaUploadReceiver).to receive(:new).and_return(receiver)
    allow(receiver).to receive(:call).and_raise(MediaUploadReceiver::Unavailable, "private detail")
    put "/api/v1/professional/media-uploads/#{upload.id}/content",
      params: jpeg,
      headers: session_headers(request_id: "media-content-down", origin: true).merge(
        "CONTENT_TYPE" => "image/jpeg"
      )
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)
  end

  it "contracts every completion transition and failure response" do
    upload = create_upload(byte_size: jpeg.bytesize)
    storage.write(scope: :private, key: upload.quarantine_key, body: jpeg, content_type: "image/jpeg")

    post "/api/v1/professional/media-uploads/#{upload.id}/completion",
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "media-complete-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/media-uploads/#{upload.id}/completion",
      headers: session_headers(
        request_id: "media-complete-origin",
        origin: "https://untrusted.example"
      )
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/media-uploads/#{SecureRandom.uuid}/completion",
      headers: session_headers(request_id: "media-complete-missing", origin: true)
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    conflicted = create_upload(byte_size: 10)
    conflicted.update!(state: "failed", failure_code: "invalid_image")
    post "/api/v1/professional/media-uploads/#{conflicted.id}/completion",
      headers: session_headers(request_id: "media-complete-conflict", origin: true)
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mismatched = create_upload(byte_size: jpeg.bytesize + 1)
    storage.write(scope: :private, key: mismatched.quarantine_key, body: jpeg, content_type: "image/jpeg")
    post "/api/v1/professional/media-uploads/#{mismatched.id}/completion",
      headers: session_headers(request_id: "media-complete-invalid", origin: true)
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    completer = instance_double(MediaUploadCompleter)
    allow(MediaUploadCompleter).to receive(:new).and_return(completer)
    allow(completer).to receive(:call).and_raise(MediaUploadCompleter::Unavailable, "private detail")
    post "/api/v1/professional/media-uploads/#{upload.id}/completion",
      headers: session_headers(request_id: "media-complete-down", origin: true)
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)
  end

  it "contracts retry success and every rejected retry boundary" do
    upload = create_upload(byte_size: jpeg.bytesize)
    storage.write(scope: :private, key: upload.quarantine_key, body: jpeg, content_type: "image/jpeg")
    upload.update!(state: "failed", failure_code: "storage_unavailable")

    expect do
      post "/api/v1/professional/media-uploads/#{upload.id}/retry",
        headers: session_headers(request_id: "media-retry", origin: true)
    end.to have_enqueued_job(MediaUploadProcessingJob).with(upload.id)
    expect(response).to have_http_status(:accepted)
    assert_api_conform(status: 202)

    post "/api/v1/professional/media-uploads/#{upload.id}/retry",
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "media-retry-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/media-uploads/#{upload.id}/retry",
      headers: session_headers(request_id: "media-retry-origin", origin: "https://untrusted.example")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/media-uploads/#{SecureRandom.uuid}/retry",
      headers: session_headers(request_id: "media-retry-missing", origin: true)
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/media-uploads/#{upload.id}/retry",
      headers: session_headers(request_id: "media-retry-conflict", origin: true)
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    retry_service = instance_double(MediaUploadRetry)
    allow(MediaUploadRetry).to receive(:new).and_return(retry_service)
    allow(retry_service).to receive(:call).and_raise(MediaUploadRetry::Unavailable, "private detail")
    transient = create_upload(byte_size: jpeg.bytesize)
    transient.update!(state: "failed", failure_code: "storage_unavailable")
    post "/api/v1/professional/media-uploads/#{transient.id}/retry",
      headers: session_headers(request_id: "media-retry-down", origin: true)
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)
  end

  private

  def create_upload(byte_size:, content_type: "image/jpeg")
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      declared_content_type: content_type,
      declared_byte_size: byte_size,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 10.minutes.from_now
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
