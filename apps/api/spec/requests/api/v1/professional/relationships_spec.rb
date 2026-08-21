# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional relationship requests", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:initiator_account) do
    UserAccount.create!(
      phone_e164: "+5547999981101",
      role: "professional",
      status: "active",
      phone_verified_at: Time.current,
      registered_at: Time.current,
      terms_accepted_at: Time.current,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
  end
  let(:initiator) do
    ProfessionalProfile.create!(user_account: initiator_account, display_name: "Ana Iniciadora")
  end
  let(:recipient) { create_published_profile("+5547999981102", "Beto Publicado") }
  let(:session_token) do
    initiator
    ApplicationSession.issue!(user_account: initiator_account).last
  end

  before do
    initiator.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      submitted_at: 1.day.ago,
      verified_at: Time.current
    )
  end

  it "creates a normalized private pending request and records meaningful activity" do
    post "/api/v1/professional/relationships",
      params: relationship_params(context_note: "  Executamos uma reforma juntos.  "),
      headers: session_headers(request_id: "relationship-create", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    relationship = ProfessionalRelationship.sole
    expect(response.headers["Location"]).to end_with(relationship.id)
    expect(response.parsed_body.dig("data", "relationship")).to include(
      "id" => relationship.id,
      "relationship_type" => "recommendation",
      "context_note" => "Executamos uma reforma juntos.",
      "status" => "pending",
      "source" => "existing_profile",
      "responded_at" => nil,
      "recipient" => hash_including(
        "id" => recipient.id,
        "public_slug" => recipient.public_slug,
        "display_name" => "Beto Publicado",
        "profile_type" => "self_service",
        "profile_available" => true
      )
    )
    expect(response.body).not_to include(recipient.user_account.phone_e164)
    expect(ProfessionalDailyActivity.sole).to have_attributes(
      professional: initiator,
      relationship_interactions: 1
    )
    assert_api_conform(status: 201)
  end

  it "requires an approved identity and a currently published recipient" do
    initiator.verification_requests.update_all(status: "expired")

    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-unverified", origin: true),
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(ProfessionalRelationship.count).to eq(0)
    expect(ProfessionalDailyActivity.count).to eq(0)
    assert_api_conform(status: 403)

    initiator.verification_requests.update_all(status: "approved")
    recipient.update!(profile_status: "suspended")
    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-private-target", origin: true),
      as: :json

    expect(response).to have_http_status(:not_found)
    expect(ProfessionalRelationship.count).to eq(0)
    assert_api_conform(status: 404)
  end

  it "rejects self relationships and invalid public input without activity" do
    publish_profile!(initiator)

    post "/api/v1/professional/relationships",
      params: relationship_params(recipient_id: initiator.id),
      headers: session_headers(request_id: "relationship-self", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "message")).to eq(
      "Revise os dados da solicitação de conexão."
    )
    expect(response.parsed_body.dig("error", "field_errors")).to be_present
    assert_api_conform(status: 422)

    post "/api/v1/professional/relationships",
      params: relationship_params(relationship_type: "follow"),
      headers: session_headers(request_id: "relationship-type", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ProfessionalRelationship.count).to eq(0)
    expect(ProfessionalDailyActivity.count).to eq(0)
  end

  it "returns conflict for an exact directional duplicate while preserving the first activity" do
    ProfessionalRelationshipRequester.new.call(
      initiator:,
      target: {type: "profile", professional_profile_id: recipient.id},
      relationship_type: "recommendation",
      context_note: nil
    )

    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-duplicate", origin: true),
      as: :json

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("relationship_conflict")
    expect(response.parsed_body.dig("error", "message")).to eq(
      "Esta solicitação de conexão já existe."
    )
    expect(ProfessionalRelationship.count).to eq(1)
    expect(ProfessionalDailyActivity.sole.relationship_interactions).to eq(1)
    assert_api_conform(status: 409)
  end

  it "denies anonymous and invalid-origin mutations" do
    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: {"X-Request-Id" => "relationship-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/relationships",
      params: relationship_params,
      headers: session_headers(request_id: "relationship-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    relationship = create_pending_relationship
    delete "/api/v1/professional/relationships/#{relationship.id}",
      headers: {
        "X-Request-Id" => "relationship-delete-anonymous",
        "Origin" => ENV.fetch("WEB_ORIGIN")
      },
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/professional/relationships/#{relationship.id}",
      headers: session_headers(
        request_id: "relationship-delete-origin",
        origin: "https://untrusted.example"
      ),
      as: :json
    expect(response).to have_http_status(:forbidden)
    expect(relationship.reload.deleted_at).to be_nil
    assert_api_conform(status: 403)
  end

  it "lets only the recipient accept once and records the response activity" do
    relationship = create_pending_relationship
    publish_profile!(initiator)
    now = Time.zone.parse("2026-08-18 14:30:00 UTC")
    travel_to(now) do
      post "/api/v1/professional/relationships/#{relationship.id}/response",
        params: {response: "accepted"},
        headers: session_headers(
          request_id: "relationship-accept",
          origin: true,
          token: recipient_session_token
        ),
        as: :json
    end

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "relationship")).to include(
      "id" => relationship.id,
      "status" => "accepted",
      "responded_at" => now.iso8601(3)
    )
    expect(relationship.reload).to have_attributes(status: "accepted", responded_at: now)
    expect(PublicProfessionalRelationshipQuery.for_professional(recipient.id)).to contain_exactly(relationship)
    expect(ModerationAction.where(target_type: "professional_relationship")).to be_empty
    expect(
      ProfessionalDailyActivity.find_by!(professional: recipient).relationship_interactions
    ).to eq(1)
    assert_api_conform(status: 200)

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "declined"},
      headers: session_headers(
        request_id: "relationship-repeat",
        origin: true,
        token: recipient_session_token
      ),
      as: :json

    expect(response).to have_http_status(:conflict)
    expect(relationship.reload).to have_attributes(status: "accepted", responded_at: now)
    expect(
      ProfessionalDailyActivity.find_by!(professional: recipient).relationship_interactions
    ).to eq(1)
    assert_api_conform(status: 409)
  end

  it "lets the recipient decline while keeping the relationship private" do
    relationship = create_pending_relationship(relationship_type: "worked_together")

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "declined"},
      headers: session_headers(
        request_id: "relationship-decline",
        origin: true,
        token: recipient_session_token
      ),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(relationship.reload.status).to eq("declined")
    expect(PublicProfessionalRelationshipQuery.for_professional(recipient.id)).to be_empty
    assert_api_conform(status: 200)
  end

  it "lets either party remove an accepted relationship and request it again" do
    relationship = create_pending_relationship
    relationship.update!(status: "accepted", responded_at: Time.current)
    publish_profile!(initiator)

    delete "/api/v1/professional/relationships/#{relationship.id}",
      headers: session_headers(request_id: "relationship-remove", origin: true)

    expect(response).to have_http_status(:ok)
    expect(relationship.reload.deleted_at).to be_present
    expect(response.parsed_body.dig("data", "relationships")).to be_empty
    expect(PublicProfessionalRelationshipQuery.for_professional(initiator.id)).to be_empty
    expect(ProfessionalDailyActivity.find_by!(professional: initiator).relationship_interactions).to eq(1)
    assert_api_conform(status: 200)

    replacement = ProfessionalRelationshipRequester.new.call(
      initiator:,
      target: {type: "profile", professional_profile_id: recipient.id},
      relationship_type: relationship.relationship_type,
      context_note: "Voltamos a trabalhar juntos."
    )
    expect(replacement).to have_attributes(status: "pending", deleted_at: nil)

    recipient_owned = create_pending_relationship(relationship_type: "worked_together")
    recipient_owned.update!(status: "accepted", responded_at: Time.current)
    delete "/api/v1/professional/relationships/#{recipient_owned.id}",
      headers: session_headers(
        request_id: "relationship-remove-recipient",
        origin: true,
        token: recipient_session_token
      )

    expect(response).to have_http_status(:ok)
    expect(recipient_owned.reload.deleted_at).to be_present
    assert_api_conform(status: 200)
  end

  it "lets the initiator cancel a pending request but not the recipient" do
    cancellable = create_pending_relationship

    delete "/api/v1/professional/relationships/#{cancellable.id}",
      headers: session_headers(request_id: "relationship-cancel", origin: true)

    expect(response).to have_http_status(:ok)
    expect(cancellable.reload.deleted_at).to be_present
    assert_api_conform(status: 200)

    recipient_pending = create_pending_relationship(relationship_type: "worked_together")
    delete "/api/v1/professional/relationships/#{recipient_pending.id}",
      headers: session_headers(
        request_id: "relationship-recipient-cancel",
        origin: true,
        token: recipient_session_token
      )

    expect(response).to have_http_status(:not_found)
    expect(recipient_pending.reload.deleted_at).to be_nil
    assert_api_conform(status: 404)
  end

  it "does not let the initiator or an anonymous session respond" do
    relationship = create_pending_relationship

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "accepted"},
      headers: session_headers(request_id: "relationship-wrong-owner", origin: true),
      as: :json

    expect(response).to have_http_status(:not_found)
    expect(relationship.reload.status).to eq("pending")
    assert_api_conform(status: 404)

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "accepted"},
      headers: {"X-Request-Id" => "relationship-response-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json

    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  it "rejects a response from an invalid origin" do
    relationship = create_pending_relationship

    post "/api/v1/professional/relationships/#{relationship.id}/response",
      params: {response: "accepted"},
      headers: session_headers(
        request_id: "relationship-response-origin",
        origin: "https://untrusted.example",
        token: recipient_session_token
      ),
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(relationship.reload.status).to eq("pending")
    assert_api_conform(status: 403)
  end

  it "creates an unregistered external account and a minimal searchable profile from an attested phone contact" do
    service = create_external_service
    Neighborhood.create!(
      code: "america-relacao",
      state_code: "SC",
      city_code: "Joinville",
      name: "América",
      is_active: true,
      sort_order: 0
    )
    now = Time.zone.parse("2026-08-20 15:30:00 UTC")

    travel_to(now) do
      post "/api/v1/professional/relationships",
        params: external_relationship_params(
          name: "  Carla   Pinturas  ",
          phone: "(47) 99998-1203",
          service_ids: [service.id],
          neighborhood_codes: ["america-relacao"]
        ),
        headers: session_headers(request_id: "relationship-external-create", origin: true),
        as: :json
    end

    expect(response).to have_http_status(:created)
    account = UserAccount.find_by!(phone_e164: "+5547999981203")
    profile = account.professional_profile
    revision = profile.published_revision
    relationship = ProfessionalRelationship.find_by!(recipient_professional: profile)
    expect(account).to have_attributes(
      role: "professional",
      status: "active",
      phone_verified_at: nil,
      registered_at: nil
    )
    expect(profile).to have_attributes(
      creation_source: "external",
      profile_status: "published",
      external_published_at: now,
      working_revision: revision,
      published_revision: revision
    )
    expect(revision).to have_attributes(
      profile_type: "external",
      status: "pending_review",
      display_name: "Carla Pinturas",
      whatsapp_e164: "+5547999981203",
      submitted_at: now
    )
    expect(revision.professional_profile_services.sole).to have_attributes(
      service:,
      is_primary: true
    )
    expect(revision.professional_profile_service_areas.sole.neighborhood_code).to eq("america-relacao")
    expect(relationship).to have_attributes(
      initiator_professional: initiator,
      source: "external_phone",
      status: "pending",
      contact_publication_attested_at: now
    )
    public_profile = PublicProfessionalProfileSerializer.new(profile).as_json
    expect(public_profile).to include(
      profile_type: "external",
      claimed: false,
      display_name: "Carla Pinturas",
      photo_url: nil,
      headline: nil,
      bio: nil,
      portfolio: [],
      relationships: []
    )
    expect(
      PublicProfessionalSearch.new.call(
        term: service.name,
        neighborhood_code: "america-relacao"
      ).professionals
    ).to contain_exactly(profile)
    expect(response.body).not_to include("+5547999981203", "999981203")
    expect(response.parsed_body.dig("data", "relationship")).to include(
      "source" => "external_phone",
      "recipient" => hash_including(
        "id" => profile.id,
        "profile_type" => "external",
        "profile_available" => true
      )
    )
    assert_api_conform(status: 201)
  end

  it "supports an external profile without optional services or coverage and reuses an existing phone owner" do
    post "/api/v1/professional/relationships",
      params: external_relationship_params(
        name: "Carla Sem Área",
        phone: "+55 47 99998-1204"
      ),
      headers: session_headers(request_id: "relationship-external-minimal", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    external_profile = UserAccount.find_by!(phone_e164: "+5547999981204").professional_profile
    projection = PublicProfessionalProfileSerializer.new(external_profile).as_json
    expect(projection).to include(
      profile_type: "external",
      services: [],
      coverage: {all_joinville: false, neighborhoods: []}
    )
    expect(external_profile).to be_publicly_available
    expect(external_profile).not_to be_search_eligible

    existing_account = UserAccount.create!(
      phone_e164: "+5547999981205",
      role: "professional",
      status: "active"
    )
    existing_profile = ProfessionalProfile.create!(
      user_account: existing_account,
      display_name: "Nome Já Existente"
    )
    post "/api/v1/professional/relationships",
      params: external_relationship_params(
        name: "Nome Que Não Deve Substituir",
        phone: "(47) 99998-1205",
        relationship_type: "worked_together"
      ),
      headers: session_headers(request_id: "relationship-external-reuse", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    expect(UserAccount.find_by!(phone_e164: "+5547999981205")).to eq(existing_account)
    expect(existing_profile.reload.display_name).to eq("Nome Já Existente")
    expect(ProfessionalProfile.where(user_account: existing_account)).to contain_exactly(existing_profile)
    expect(ProfessionalRelationship.find_by!(recipient_professional: existing_profile)).to have_attributes(
      recipient_professional: existing_profile,
      source: "external_phone"
    )
  end

  it "requires contact attestation, rejects the initiator phone, and hides an unclaimed external profile after cancellation" do
    post "/api/v1/professional/relationships",
      params: external_relationship_params(
        name: "Contato Sem Consentimento",
        phone: "(47) 99998-1206",
        attested: false
      ),
      headers: session_headers(request_id: "relationship-external-consent", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(UserAccount.find_by(phone_e164: "+5547999981206")).to be_nil

    post "/api/v1/professional/relationships",
      params: external_relationship_params(
        name: "Própria Iniciadora",
        phone: initiator_account.phone_e164
      ),
      headers: session_headers(request_id: "relationship-external-self", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "phone")).to be_present

    post "/api/v1/professional/relationships",
      params: external_relationship_params(
        name: "Contato Cancelado",
        phone: "(47) 99998-1207",
        relationship_type: "worked_together"
      ),
      headers: session_headers(request_id: "relationship-external-cancellable", origin: true),
      as: :json
    relationship = ProfessionalRelationship.find_by!(
      recipient_professional: UserAccount.find_by!(phone_e164: "+5547999981207").professional_profile
    )
    external_profile = relationship.recipient_professional
    expect(external_profile).to be_publicly_available

    delete "/api/v1/professional/relationships/#{relationship.id}",
      headers: session_headers(request_id: "relationship-external-cancel", origin: true)

    expect(response).to have_http_status(:ok)
    expect(external_profile.reload).not_to be_publicly_available
    expect do
      PublicProfessionalProfileQuery.new.call(slug: external_profile.public_slug)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  private

  def relationship_params(
    recipient_id: recipient.id,
    relationship_type: "recommendation",
    context_note: nil
  )
    {
      relationship: {
        target: {
          type: "profile",
          professional_profile_id: recipient_id
        },
        relationship_type:,
        context_note:
      }
    }
  end

  def external_relationship_params(
    name:,
    phone:,
    relationship_type: "recommendation",
    service_ids: [],
    neighborhood_codes: [],
    all_joinville: false,
    attested: true
  )
    {
      relationship: {
        target: {
          type: "phone",
          name:,
          phone:,
          service_ids:,
          coverage: {
            all_joinville:,
            neighborhood_codes:
          },
          contact_publication_attested: attested
        },
        relationship_type:,
        context_note: "Indicação feita pelo fluxo simplificado."
      }
    }
  end

  def create_external_service
    category = ServiceCategory.create!(
      name: "Relações externas",
      slug: "relacoes-externas",
      icon: "i-lucide-paint-roller",
      is_active: true,
      sort_order: 0
    )
    Service.create!(
      category:,
      name: "Pintura externa",
      slug: "pintura-externa",
      icon: "i-lucide-paint-roller",
      description: "Pintura para perfis externos.",
      aliases: ["pintor externo"],
      is_active: true,
      sort_order: 0
    )
  end

  def create_published_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name)
    publish_profile!(profile)
  end

  def create_pending_relationship(relationship_type: "recommendation")
    ProfessionalRelationship.create!(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type:,
      context_note: "Executamos uma reforma juntos."
    )
  end

  def recipient_session_token
    @recipient_session_token ||= ApplicationSession.issue!(user_account: recipient.user_account).last
  end

  def publish_profile!(profile)
    make_profile_publicly_eligible(profile)
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
