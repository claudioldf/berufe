# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public portfolio images", type: :request, openapi: true do
  let(:account) { UserAccount.create!(phone_e164: "+5547999998208", role: "professional", status: "active") }
  let(:profile) do
    record = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
    make_profile_publicly_eligible(record)
  end
  let(:service) { create_service }
  let(:storage) { instance_double(LocalDiskStorage) }

  before do
    allow(MediaStorage).to receive(:build).and_return(storage)
    allow(storage).to receive(:read)
  end

  it "serves active JPEG and PNG images from private storage without exposing keys" do
    jpeg = create_item(content_type: "image/jpeg")
    png = create_item(content_type: "image/png")
    allow(storage).to receive(:read).with(scope: :private, key: jpeg.private_key).and_return("jpeg-image")
    allow(storage).to receive(:read).with(scope: :private, key: png.private_key).and_return("png-image")

    get "/api/v1/public/portfolio-items/#{jpeg.id}/image", headers: {"X-Request-Id" => "portfolio-image-jpeg"}
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("jpeg-image")
    expect(response.media_type).to eq("image/jpeg")
    expect(response.headers.fetch("Cache-Control")).to eq("max-age=0, public, must-revalidate")
    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    expect(response.headers.fetch("Content-Disposition")).to start_with("inline; filename=\"berufe-portfolio-#{jpeg.id}.jpg\"")
    assert_api_conform(status: 200)

    get "/api/v1/public/portfolio-items/#{png.id}/image", headers: {"X-Request-Id" => "portfolio-image-png"}
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("png-image")
    expect(response.media_type).to eq("image/png")
    assert_api_conform(status: 200)
  end

  it "keeps the same image link public without moderation transitions" do
    item = create_item
    allow(storage).to receive(:read).with(scope: :private, key: item.private_key).and_return("image")

    get "/api/v1/public/portfolio-items/#{item.id}/image", headers: {"X-Request-Id" => "portfolio-image-pending"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("image")
    expect(response.headers.fetch("Cache-Control")).to eq("max-age=0, public, must-revalidate")
    assert_api_conform(status: 200)
  end

  it "unpublishes the image link when the owner deletes the item" do
    item = create_item
    item.update!(deleted_at: Time.current)
    get "/api/v1/public/portfolio-items/#{item.id}/image", headers: {"X-Request-Id" => "portfolio-image-after-rejection"}

    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "revalidates the parent professional on every image read" do
    item = create_item
    allow(storage).to receive(:read).with(scope: :private, key: item.private_key).and_return("image")
    account.update!(status: "suspended")

    get "/api/v1/public/portfolio-items/#{item.id}/image", headers: {"X-Request-Id" => "portfolio-parent-private"}

    expect(response).to have_http_status(:not_found)
    expect(storage).not_to have_received(:read)
    assert_api_conform(status: 404)
  end

  private

  def create_service
    category = ServiceCategory.create!(
      name: "Imagem Pública",
      slug: "imagem-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista-imagem-publica",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  def create_item(content_type: "image/png")
    extension = (content_type == "image/png") ? "png" : "jpg"
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "attached",
      declared_content_type: content_type,
      declared_byte_size: 120,
      actual_content_type: content_type,
      sanitized_content_type: content_type,
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 380,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.#{extension}",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title: "Trabalho #{extension}",
      private_key: upload.sanitized_key,
      content_type:,
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at: Time.current
    )
  end
end
