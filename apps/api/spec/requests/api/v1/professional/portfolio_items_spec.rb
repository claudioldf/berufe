# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional portfolio items", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996206", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
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
    ProfessionalProfileService.create!(
      professional_profile_revision: profile.working_revision,
      service: created,
      is_primary: true
    )
    created
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "creates a private pending item and returns it through the owned workspace" do
    upload = processed_upload

    post "/api/v1/professional/portfolio-items",
      params: create_params(upload),
      headers: session_headers(request_id: "portfolio-create", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    expect(response.headers["Location"]).to end_with(PortfolioItem.last.id)
    expect(response.parsed_body.dig("data", "profile", "portfolio_items")).to contain_exactly(
      hash_including(
        "id" => PortfolioItem.last.id,
        "title" => "Cozinha iluminada",
        "description" => "Instalação completa.",
        "service" => {"id" => service.id, "name" => service.name},
        "status" => "pending_review",
        "rejection_reason" => nil,
        "image_url" => nil
      )
    )
    expect(ProfessionalDailyActivity.sole).to have_attributes(
      professional: profile,
      evidence_creations: 1
    )
    assert_api_conform(status: 201)
  end

  it "rejects invalid or unselected item data" do
    post "/api/v1/professional/portfolio-items",
      params: create_params(processed_upload).deep_merge(
        portfolio_item: {service_id: SecureRandom.uuid}
      ),
      headers: session_headers(request_id: "portfolio-invalid", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "service_id")).to be_present
    assert_api_conform(status: 422)
  end

  it "soft-deletes an owned item and removes it from the workspace projection" do
    item = create_portfolio_item

    delete "/api/v1/professional/portfolio-items/#{item.id}",
      headers: session_headers(request_id: "portfolio-delete", origin: true)

    expect(response).to have_http_status(:ok)
    expect(item.reload.deleted_at).to be_present
    expect(response.parsed_body.dig("data", "profile", "portfolio_items")).to eq([])
    assert_api_conform(status: 200)
  end

  it "denies anonymous create and delete requests" do
    post "/api/v1/professional/portfolio-items",
      params: contract_create_params,
      headers: {"X-Request-Id" => "portfolio-create-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      headers: {"X-Request-Id" => "portfolio-delete-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  it "denies invalid origins for create and delete" do
    post "/api/v1/professional/portfolio-items",
      params: contract_create_params,
      headers: session_headers(request_id: "portfolio-create-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    delete "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      headers: session_headers(request_id: "portfolio-delete-origin", origin: "https://untrusted.example")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  it "returns not found for an unregistered professional or missing owned item" do
    unregistered = UserAccount.create!(phone_e164: "+5547999996207", role: "professional", status: "active")
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    post "/api/v1/professional/portfolio-items",
      params: contract_create_params,
      headers: session_headers(
        request_id: "portfolio-create-missing",
        origin: true,
        token: unregistered_token
      ),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    delete "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      headers: session_headers(request_id: "portfolio-delete-missing", origin: true)
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def create_params(upload)
    {
      portfolio_item: {
        media_upload_id: upload.id,
        service_id: service.id,
        title: "Cozinha iluminada",
        description: "Instalação completa."
      }
    }
  end

  def contract_create_params
    {
      portfolio_item: {
        media_upload_id: SecureRandom.uuid,
        service_id: SecureRandom.uuid,
        title: "Cozinha iluminada",
        description: nil
      }
    }
  end

  def create_portfolio_item
    PortfolioItemCreator.new.call(
      profile:,
      attributes: create_params(processed_upload).fetch(:portfolio_item)
    )
  end

  def processed_upload
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "processed",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 380,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
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
