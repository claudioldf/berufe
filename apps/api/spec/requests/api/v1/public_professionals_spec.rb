# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public professional profiles", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Perfil público",
      slug: "perfil-publico",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:primary_service) { create_service("Eletricista público", "eletricista-publico", 0) }
  let!(:additional_service) { create_service("Marido de aluguel público", "marido-de-aluguel-publico", 1) }
  let!(:neighborhood) do
    Neighborhood.create!(
      code: "america-perfil-publico",
      name: "América Perfil Público",
      state_code: "SC",
      city_code: "Joinville",
      is_active: true,
      sort_order: 0
    )
  end

  it "returns the complete approved projection and a profile-bound search interaction" do
    profile = create_published_profile(
      phone: "+5547999997701",
      name: "Ana Souza Pública",
      slug: "ana-souza-publica",
      services: [primary_service, additional_service],
      instagram: "https://www.instagram.com/berufe.ana/",
      youtube: "https://www.youtube.com/@berufe-ana"
    )
    photo = profile.published_photo
    approved_portfolio = create_portfolio(profile, status: "approved", service: primary_service)
    create_portfolio(profile, status: "hidden", service: additional_service)
    create_identity(profile, status: "approved")
    create_identity(profile, status: "pending_review")
    partner = create_published_profile(
      phone: "+5547999997702",
      name: "Beto Parceiro Público",
      slug: "beto-parceiro-publico",
      services: [additional_service]
    )
    relationship = create_public_relationship(profile, partner)
    pending_relationship = create_private_relationship(profile, partner)
    search_event = SearchEvent.create!(
      service: additional_service,
      query_text_normalized: "marido de aluguel publico",
      city_code: "Joinville",
      neighborhood:,
      result_count: 1
    )
    search_token = PublicInteractionToken.new.issue(
      search_event_id: search_event.id,
      service_id: additional_service.id
    )

    get "/api/v1/public/professionals/#{profile.public_slug}",
      params: {interaction_token: search_token},
      headers: {"X-Request-Id" => "public-profile-200"}

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    professional = data.fetch("professional")
    expect(professional).to include(
      "id" => profile.id,
      "public_slug" => "ana-souza-publica",
      "display_name" => "Ana Souza Pública",
      "headline" => "Elétrica residencial com cuidado.",
      "bio" => "Instalações e reparos residenciais em Joinville.",
      "years_experience" => 11,
      "photo_url" => PublicProfilePhotoImageUrl.call(photo),
      "public_snapshot_updated_at" => profile.published_revision.reviewed_at.iso8601
    )
    expect(professional.fetch("services")).to eq([
      {
        "id" => primary_service.id,
        "name" => primary_service.name,
        "slug" => primary_service.slug,
        "icon" => primary_service.icon,
        "is_primary" => true,
        "note" => "Quadros elétricos"
      },
      {
        "id" => additional_service.id,
        "name" => additional_service.name,
        "slug" => additional_service.slug,
        "icon" => additional_service.icon,
        "is_primary" => false,
        "note" => "Pequenos reparos"
      }
    ])
    expect(professional.fetch("coverage")).to eq(
      "all_joinville" => false,
      "neighborhoods" => [{"code" => neighborhood.code, "name" => neighborhood.name}]
    )
    expect(professional.fetch("verification_labels")).to contain_exactly(
      {"type" => "phone", "label" => "Telefone confirmado", "verified_at" => nil},
      include("type" => "identity", "label" => "Identidade verificada")
    )
    expect(professional.fetch("portfolio")).to eq([
      {
        "id" => approved_portfolio.id,
        "title" => approved_portfolio.title,
        "description" => approved_portfolio.description,
        "service" => {
          "id" => primary_service.id,
          "name" => primary_service.name,
          "slug" => primary_service.slug
        },
        "image_url" => PublicPortfolioImageUrl.call(approved_portfolio)
      }
    ])
    expect(professional.fetch("relationships")).to eq([
      {
        "id" => pending_relationship.id,
        "type" => "worked_together",
        "direction" => "outgoing",
        "note" => "Não revisada.",
        "professional" => {
          "id" => partner.id,
          "public_slug" => partner.public_slug,
          "display_name" => "Beto Parceiro Público",
          "photo_url" => PublicProfilePhotoImageUrl.call(partner.published_photo)
        }
      },
      {
        "id" => relationship.id,
        "type" => "recommendation",
        "direction" => "incoming",
        "note" => "Indicação profissional aprovada.",
        "professional" => {
          "id" => partner.id,
          "public_slug" => partner.public_slug,
          "display_name" => "Beto Parceiro Público",
          "photo_url" => PublicProfilePhotoImageUrl.call(partner.published_photo)
        }
      }
    ])
    expect(professional.fetch("social_links")).to eq(
      "instagram" => "https://www.instagram.com/berufe.ana/",
      "youtube" => "https://www.youtube.com/@berufe-ana"
    )
    interaction = PublicProfileInteractionToken.new.verify(data.dig("interaction", "token"))
    expect(interaction).to have_attributes(
      professional_id: profile.id,
      service_id: additional_service.id,
      search_event_id: search_event.id
    )
    expect(response.headers.fetch("Cache-Control")).to eq("max-age=0, public, must-revalidate")
    expect(response.body).not_to include(
      profile.published_revision.whatsapp_e164,
      "+5547",
      "private_key",
      "review_note",
      "pending_review"
    )
    assert_api_conform(status: 200)
  end

  it "renders a valid direct interaction when incoming search context is invalid" do
    profile = create_published_profile(
      phone: "+5547999997703",
      name: "Contato Direto Público",
      slug: "contato-direto-publico",
      services: [primary_service]
    )

    get "/api/v1/public/professionals/#{profile.public_slug}",
      params: {interaction_token: "invalid"},
      headers: {"X-Request-Id" => "public-profile-direct"}

    expect(response).to have_http_status(:ok)
    interaction = PublicProfileInteractionToken.new.verify(
      response.parsed_body.dig("data", "interaction", "token")
    )
    expect(interaction).to have_attributes(
      professional_id: profile.id,
      service_id: primary_service.id,
      search_event_id: nil
    )
    assert_api_conform(status: 200)
  end

  it "returns the same generic not-found envelope for unknown, draft, and suspended profiles" do
    draft = ProfessionalProfile.create!(
      user_account: UserAccount.create!(phone_e164: "+5547999997704", role: "professional", status: "active"),
      display_name: "Perfil Privado"
    )
    published = create_published_profile(
      phone: "+5547999997705",
      name: "Perfil Suspenso",
      slug: "perfil-suspenso-publico",
      services: [primary_service]
    )
    published.user_account.update!(status: "suspended")

    ["slug-desconhecido", draft.public_slug, published.public_slug].each do |slug|
      get "/api/v1/public/professionals/#{slug}", headers: {"X-Request-Id" => "public-profile-404"}
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    end
    assert_api_conform(status: 404)
  end

  it "uses the safe unavailable response when the profile query fails" do
    allow(PublicProfessionalProfileQuery).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/professionals/perfil-indisponivel",
      headers: {"X-Request-Id" => "public-profile-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def create_service(name, slug, sort_order)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-wrench",
      description: "Serviço residencial público.",
      aliases: [],
      is_active: true,
      sort_order:
    )
  end

  def create_published_profile(phone:, name:, slug:, services:, instagram: nil, youtube: nil)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(
      user_account: account,
      public_slug: slug,
      display_name: name,
      headline: "Elétrica residencial com cuidado.",
      bio: "Instalações e reparos residenciais em Joinville.",
      years_experience: 11,
      whatsapp_e164: phone,
      instagram_url: instagram,
      youtube_url: youtube
    )
    revision = profile.working_revision
    services.each_with_index do |service, index|
      revision.professional_profile_services.create!(
        service:,
        is_primary: index.zero?,
        note: index.zero? ? "Quadros elétricos" : "Pequenos reparos"
      )
    end
    revision.professional_profile_service_areas.create!(city_code: "Joinville", neighborhood:)
    make_profile_publicly_eligible(profile, revision:)
  end

  def create_photo(profile)
    upload = create_upload(profile, purpose: "profile_photo", content_type: "image/jpeg")
    profile.profile_photos.create!(
      media_upload: upload,
      status: "approved",
      private_key: upload.sanitized_key,
      public_key: "moderation/profile_photo/#{SecureRandom.uuid}.jpg",
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago
    )
  end

  def create_portfolio(profile, status:, service:)
    upload = create_upload(profile, purpose: "portfolio_image", content_type: "image/png")
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title: "Quadro organizado #{status}",
      description: "Organização e identificação do quadro.",
      status:,
      private_key: upload.sanitized_key,
      public_key: ("moderation/portfolio_item/#{SecureRandom.uuid}.png" if status == "approved"),
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at: Time.current,
      reviewed_at: (Time.current if status == "approved")
    )
  end

  def create_upload(profile, purpose:, content_type:)
    extension = (content_type == "image/png") ? "png" : "jpg"
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "attached",
      declared_content_type: content_type,
      declared_byte_size: 120,
      actual_content_type: content_type,
      sanitized_content_type: content_type,
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: (purpose == "profile_photo") ? 960 : 380,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.#{extension}",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
  end

  def create_identity(profile, status:)
    profile.verification_requests.create!(
      verification_type: "identity",
      status:,
      public_label: (ModerationDecision::IDENTITY_LABEL if status == "approved"),
      submitted_at: 2.days.ago,
      reviewed_at: (1.day.ago if status == "approved"),
      verified_at: (1.day.ago if status == "approved")
    )
  end

  def create_public_relationship(profile, partner)
    ProfessionalRelationship.create!(
      initiator_professional: partner,
      recipient_professional: profile,
      relationship_type: "recommendation",
      context_note: "Indicação profissional aprovada.",
      status: "accepted",
      responded_at: Time.current
    )
  end

  def create_private_relationship(profile, partner)
    ProfessionalRelationship.create!(
      initiator_professional: profile,
      recipient_professional: partner,
      relationship_type: "worked_together",
      context_note: "Não revisada.",
      status: "accepted",
      responded_at: Time.current
    )
  end
end
