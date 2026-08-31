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

  it "updates and resubmits a rejected item without creating another item" do
    item = create_portfolio_item
    original_upload_id = item.media_upload_id
    item.update!(
      status: "rejected",
      rejection_reason: "A descrição precisa explicar melhor o trabalho realizado.",
      reviewed_at: 1.day.ago
    )

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_params(title: "Cozinha revisada", description: "Descrição corrigida."),
      headers: session_headers(request_id: "portfolio-update", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(profile.portfolio_items.active.count).to eq(1)
    expect(item.reload).to have_attributes(
      media_upload_id: original_upload_id,
      service:,
      title: "Cozinha revisada",
      description: "Descrição corrigida.",
      status: "pending_review",
      rejection_reason: nil,
      reviewed_at: nil,
      hidden_at: nil
    )
    expect(response.parsed_body.dig("data", "profile", "portfolio_items")).to contain_exactly(
      hash_including("id" => item.id, "status" => "pending_review", "rejection_reason" => nil)
    )
    assert_api_conform(status: 200)
  end

  it "replaces the image while resubmitting a hidden item" do
    item = create_portfolio_item
    previous_upload_id = item.media_upload_id
    replacement = processed_upload
    item.update!(
      status: "hidden",
      rejection_reason: "A imagem precisa ser substituída antes de voltar ao perfil.",
      reviewed_at: 1.day.ago,
      hidden_at: 1.day.ago
    )

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_params(media_upload_id: replacement.id),
      headers: session_headers(request_id: "portfolio-replace", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(item.reload).to have_attributes(
      media_upload: replacement,
      private_key: replacement.sanitized_key,
      status: "pending_review",
      rejection_reason: nil,
      reviewed_at: nil,
      hidden_at: nil
    )
    expect(replacement.reload).to have_attributes(state: "attached", attached_at: be_present)
    expect(MediaUpload.find(previous_upload_id)).to be_present
    assert_api_conform(status: 200)
  end

  it "resubmits the same item when the portfolio already has 12 active works" do
    item = create_portfolio_item
    11.times { |index| create_portfolio_item(title: "Trabalho #{index}") }
    item.update!(status: "rejected", rejection_reason: "Revise a descrição do trabalho.", reviewed_at: 1.day.ago)

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_params,
      headers: session_headers(request_id: "portfolio-update-full", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(profile.portfolio_items.active.count).to eq(12)
    expect(item.reload).to be_pending_review
    assert_api_conform(status: 200)
  end

  it "rejects resubmission when the item is not rejected or hidden" do
    item = create_portfolio_item

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_params,
      headers: session_headers(request_id: "portfolio-update-conflict", origin: true),
      as: :json

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("portfolio_item_conflict")
    assert_api_conform(status: 409)
  end

  it "rejects invalid resubmission data" do
    item = create_portfolio_item
    item.update!(status: "rejected", rejection_reason: "Revise os dados enviados.", reviewed_at: 1.day.ago)

    patch "/api/v1/professional/portfolio-items/#{item.id}",
      params: update_params(service_id: SecureRandom.uuid),
      headers: session_headers(request_id: "portfolio-update-invalid", origin: true),
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

  it "denies anonymous create, update, and delete requests" do
    post "/api/v1/professional/portfolio-items",
      params: contract_create_params,
      headers: {"X-Request-Id" => "portfolio-create-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      params: update_params,
      headers: {"X-Request-Id" => "portfolio-update-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      headers: {"X-Request-Id" => "portfolio-delete-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  it "denies invalid origins for create, update, and delete" do
    post "/api/v1/professional/portfolio-items",
      params: contract_create_params,
      headers: session_headers(request_id: "portfolio-create-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    patch "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      params: update_params,
      headers: session_headers(request_id: "portfolio-update-origin", origin: "https://untrusted.example"),
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

    patch "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      params: update_params,
      headers: session_headers(request_id: "portfolio-update-missing", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    delete "/api/v1/professional/portfolio-items/#{SecureRandom.uuid}",
      headers: session_headers(request_id: "portfolio-delete-missing", origin: true)
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "returns not found when resubmitting a foreign or deleted item" do
    other_account = UserAccount.create!(phone_e164: "+5547999996208", role: "professional", status: "active")
    other_profile = ProfessionalProfile.create!(user_account: other_account, display_name: "Outra Profissional")
    ProfessionalProfileService.create!(
      professional_profile_revision: other_profile.working_revision,
      service:,
      is_primary: true
    )
    foreign_item = PortfolioItemCreator.new.call(
      profile: other_profile,
      attributes: create_params(processed_upload(owner: other_profile)).fetch(:portfolio_item)
    )
    foreign_item.update!(status: "rejected", rejection_reason: "Revise o trabalho enviado.", reviewed_at: 1.day.ago)

    patch "/api/v1/professional/portfolio-items/#{foreign_item.id}",
      params: update_params,
      headers: session_headers(request_id: "portfolio-update-foreign", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    deleted_item = create_portfolio_item
    deleted_item.update!(status: "rejected", rejection_reason: "Revise o trabalho enviado.", reviewed_at: 1.day.ago)
    PortfolioItemDeleter.new.call(item: deleted_item)
    patch "/api/v1/professional/portfolio-items/#{deleted_item.id}",
      params: update_params,
      headers: session_headers(request_id: "portfolio-update-deleted", origin: true),
      as: :json
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

  def update_params(media_upload_id: nil, service_id: service.id, title: "Cozinha atualizada", description: "Instalação revisada.")
    attributes = {
      service_id:,
      title:,
      description:
    }
    attributes[:media_upload_id] = media_upload_id if media_upload_id
    {portfolio_item: attributes}
  end

  def create_portfolio_item(title: "Cozinha iluminada")
    PortfolioItemCreator.new.call(
      profile:,
      attributes: create_params(processed_upload).fetch(:portfolio_item).merge(title:)
    )
  end

  def processed_upload(owner: profile)
    MediaUpload.create!(
      professional_profile: owner,
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
