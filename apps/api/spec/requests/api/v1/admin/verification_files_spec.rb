# frozen_string_literal: true

require "rails_helper"
require "vips"

RSpec.describe "Administrator verification-file access", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "verification-file-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }
  let(:account) { UserAccount.create!(phone_e164: "+5547999998212", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:storage) { instance_double(LocalDiskStorage) }

  before do
    allow(MediaStorage).to receive(:build).and_return(storage)
    allow(storage).to receive(:read)
  end

  it "streams retained regenerated JPEG and PNG evidence and appends access audits" do
    png_body = Vips::Image.black(12, 8).pngsave_buffer
    jpeg_body = Vips::Image.black(10, 6).jpegsave_buffer
    png = create_file(body: png_body, content_type: "image/png")
    jpeg = create_file(body: jpeg_body, content_type: "image/jpeg")
    allow(storage).to receive(:read).with(scope: :private, key: png.private_key).and_return(png_body)
    allow(storage).to receive(:read).with(scope: :private, key: jpeg.private_key).and_return(jpeg_body)

    get content_path(png), headers: session_headers(admin_token, "verification-file-png")
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq(png_body)
    expect(response.media_type).to eq("image/png")
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    expect(response.headers.fetch("Content-Disposition")).to start_with("inline; filename=\"berufe-identidade-#{png.id}.png\"")
    assert_api_conform(status: 200)

    get content_path(jpeg), headers: session_headers(admin_token, "verification-file-jpeg")
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq(jpeg_body)
    expect(response.media_type).to eq("image/jpeg")
    assert_api_conform(status: 200)

    expect(VerificationFileAccessEvent.order(:created_at).pluck(:admin_user_id, :verification_file_id, :action, :request_id)).to eq(
      [
        [admin.id, png.id, "viewed", "verification-file-png"],
        [admin.id, jpeg.id, "viewed", "verification-file-jpeg"]
      ]
    )
  end

  it "denies deleted, failed/quarantined, mismatched, and unavailable evidence without auditing" do
    body = Vips::Image.black(12, 8).pngsave_buffer
    deleted = create_file(body:, content_type: "image/png", deleted_at: Time.current)
    failed = create_file(body:, content_type: "image/png", upload_state: "failed")
    corrupt = create_file(body:, content_type: "image/png")
    allow(storage).to receive(:read).with(scope: :private, key: corrupt.private_key).and_return("x" * corrupt.byte_size)

    [deleted, failed, corrupt].each_with_index do |file, index|
      get content_path(file), headers: session_headers(admin_token, "verification-file-denied-#{index}")
      expect(response).to have_http_status(:not_found)
      assert_api_conform(status: 404)
    end
    expect(VerificationFileAccessEvent.count).to eq(0)
  end

  it "requires a password-authenticated active administrator and never accepts a bearer-style link" do
    file = create_file(body: Vips::Image.black(12, 8).pngsave_buffer, content_type: "image/png")

    get content_path(file), headers: {"X-Request-Id" => "verification-file-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    professional_token = ApplicationSession.issue!(user_account: account).last
    get content_path(file), headers: session_headers(professional_token, "verification-file-professional")
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    expect do
      get "#{content_path(file)}?token=expired-or-forged", headers: {"X-Request-Id" => "verification-file-forged"}
    end.to raise_error(OpenapiFirst::Test::UnknownQueryParameterError)
    expect(VerificationFileAccessEvent.count).to eq(0)
  end

  private

  def content_path(file)
    "/api/v1/admin/verification-files/#{file.id}/content"
  end

  def session_headers(token, request_id)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
  end

  def create_file(body:, content_type:, deleted_at: nil, upload_state: "attached")
    extension = (content_type == "image/png") ? "png" : "jpg"
    image = Vips::Image.new_from_buffer(body, "")
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "verification_identity",
      state: upload_state,
      failure_code: (upload_state == "failed") ? "invalid_image" : nil,
      declared_content_type: content_type,
      declared_byte_size: body.bytesize,
      actual_content_type: content_type,
      sanitized_content_type: content_type,
      actual_byte_size: body.bytesize,
      sanitized_byte_size: body.bytesize,
      width: image.width,
      height: image.height,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.#{extension}",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: (upload_state == "attached") ? Time.current : nil
    )
    request_record = profile.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      submitted_at: Time.current,
      reviewed_at: Time.current,
      public_label: "Identidade verificada",
      verified_at: Time.current
    )
    request_record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type:,
      byte_size: body.bytesize,
      width: image.width,
      height: image.height,
      uploaded_at: Time.current,
      deleted_at:
    )
  end
end
