# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional portfolio items", type: :request, openapi: true do
  let(:account) { UserAccount.create!(phone_e164: "+5547999996206", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:service) do
    category = ServiceCategory.create!(
      name: "Portfólio Request",
      slug: "portfolio-request",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    created = Service.create!(
      category:,
      name: "Eletricista Portfolio",
      slug: "eletricista-portfolio-request",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    profile.working_revision.professional_profile_services.create!(service: created, is_primary: true)
    created
  end
  let(:token) { ApplicationSession.issue!(user_account: account).last }
  let(:storage) { instance_double(LocalDiskStorage) }

  before do
    allow(MediaStorage).to receive(:build).and_return(storage)
    allow(storage).to receive(:read)
  end

  it "creates, immediately updates, and deletes an owned item" do
    upload = processed_upload
    post "/api/v1/professional/portfolio-items",
      params: {portfolio_item: attributes(upload)},
      headers: headers("portfolio-create"),
      as: :json

    expect(response).to have_http_status(:created)
    item = PortfolioItem.sole
    expect(response.parsed_body.dig("data", "profile", "portfolio_items")).to contain_exactly(
      hash_including(
        "id" => item.id,
        "title" => "Cozinha iluminada",
        "image_url" => a_string_including("/api/v1/professional/portfolio-items/#{item.id}/image")
      )
    )
    assert_api_conform(status: 201)

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: {portfolio_item: attributes(nil).merge(title: "Cozinha atualizada")},
      headers: headers("portfolio-update"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(item.reload.title).to eq("Cozinha atualizada")
    assert_api_conform(status: 200)

    delete "/api/v1/professional/portfolio-items/#{item.id}", headers: headers("portfolio-delete")
    expect(response).to have_http_status(:ok)
    expect(item.reload.deleted_at).to be_present
    assert_api_conform(status: 200)
  end

  it "serves an active image to its owner while the profile is draft or suspended" do
    item = PortfolioItemCreator.new.call(profile:, attributes: attributes(processed_upload))
    allow(storage).to receive(:read).with(scope: :private, key: item.private_key).and_return("owner-portfolio")

    get "/api/v1/professional/portfolio-items/#{item.id}/image", headers: headers("portfolio-image-owner-draft")
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("owner-portfolio")
    expect(response.media_type).to eq("image/png")
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    assert_api_conform(status: 200)

    profile.update!(profile_status: "suspended")
    get "/api/v1/professional/portfolio-items/#{item.id}/image", headers: headers("portfolio-image-owner-suspended")
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("owner-portfolio")
    assert_api_conform(status: 200)

    jpeg_item = PortfolioItemCreator.new.call(
      profile:,
      attributes: attributes(processed_upload(content_type: "image/jpeg"))
    )
    allow(storage).to receive(:read).with(scope: :private, key: jpeg_item.private_key).and_return("owner-jpeg")

    get "/api/v1/professional/portfolio-items/#{jpeg_item.id}/image", headers: headers("portfolio-image-jpeg")
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("owner-jpeg")
    expect(response.media_type).to eq("image/jpeg")
    assert_api_conform(status: 200)
  end

  it "does not expose owner portfolio previews anonymously or after deletion" do
    item = PortfolioItemCreator.new.call(profile:, attributes: attributes(processed_upload))

    get "/api/v1/professional/portfolio-items/#{item.id}/image",
      headers: {"X-Request-Id" => "portfolio-image-owner-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    item.update!(deleted_at: Time.current)
    get "/api/v1/professional/portfolio-items/#{item.id}/image", headers: headers("portfolio-image-owner-deleted")
    expect(response).to have_http_status(:not_found)
    expect(storage).not_to have_received(:read)
    assert_api_conform(status: 404)
  end

  it "rejects unselected services and foreign items" do
    post "/api/v1/professional/portfolio-items",
      params: {portfolio_item: attributes(processed_upload).merge(service_id: SecureRandom.uuid)},
      headers: headers("portfolio-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    patch "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      params: {portfolio_item: attributes(nil)},
      headers: headers("portfolio-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "documents authentication, origin, validation, and ownership failures" do
    upload = processed_upload
    request_attributes = {portfolio_item: attributes(upload)}

    post "/api/v1/professional/portfolio-items",
      params: request_attributes,
      headers: {"X-Request-Id" => "portfolio-create-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/portfolio-items",
      params: request_attributes,
      headers: headers("portfolio-create-origin").except("Origin"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    profileless_account = UserAccount.create!(
      phone_e164: "+5547999996207",
      role: "professional",
      status: "active"
    )
    profileless_token = ApplicationSession.issue!(user_account: profileless_account).last
    post "/api/v1/professional/portfolio-items",
      params: request_attributes,
      headers: {
        "X-Request-Id" => "portfolio-create-profileless",
        "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{profileless_token}",
        "Origin" => ENV.fetch("WEB_ORIGIN")
      },
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    item = PortfolioItemCreator.new.call(profile:, attributes: attributes(upload))
    update_attributes = {portfolio_item: attributes(nil)}

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_attributes,
      headers: {"X-Request-Id" => "portfolio-update-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_attributes,
      headers: headers("portfolio-update-origin").except("Origin"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: {portfolio_item: attributes(nil).merge(service_id: SecureRandom.uuid)},
      headers: headers("portfolio-update-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    delete "/api/v1/professional/portfolio-items/#{item.id}",
      headers: {"X-Request-Id" => "portfolio-delete-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/professional/portfolio-items/#{item.id}",
      headers: headers("portfolio-delete-origin").except("Origin")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    delete "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}", headers: headers("portfolio-delete-missing")
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def attributes(upload)
    {
      media_upload_id: upload&.id,
      service_id: service.id,
      title: "Cozinha iluminada",
      description: "Instalação completa."
    }.compact
  end

  def processed_upload(content_type: "image/png")
    extension = (content_type == "image/jpeg") ? "jpg" : "png"
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "processed",
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
      processed_at: Time.current
    )
  end

  def headers(request_id)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}",
      "Origin" => ENV.fetch("WEB_ORIGIN")
    }
  end
end
