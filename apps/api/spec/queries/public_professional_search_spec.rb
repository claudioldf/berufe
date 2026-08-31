# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalSearch do
  let!(:category) do
    ServiceCategory.create!(
      name: "Busca pública",
      slug: "busca-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) { create_service("Eletricista busca", "busca-eletricista", ["elétrica"], 0) }
  let!(:plumber) { create_service("Encanador busca", "busca-encanador", ["hidráulica"], 1) }
  let!(:america) do
    create_location_neighborhood(code: "4209102013", name: "América Busca")
  end
  let!(:centro) do
    create_location_neighborhood(code: "4209102014", name: "Centro Busca")
  end
  let(:parser) { instance_double(LlmSearchParser) }
  let(:criteria) do
    LlmSearchParser::Criteria.new(
      service_ids: [electrician.id],
      locations: [LlmSearchParser::Location.new(city_code: "4209102", state_code: "SC", city: "Joinville", neighborhood_code: america.code)],
      keywords: [],
      normalized_request: "Eu preciso trocar a fiação no América."
    )
  end

  before do
    allow(parser).to receive(:call).and_return(criteria)
  end

  it "returns only eligible profiles offering the resolved service in the selected coverage" do
    all_city = create_published_profile("+5547999997401", "Ana Toda Cidade", services: [electrician], all_city: true)
    exact_area = create_published_profile(
      "+5547999997402",
      "Beto América",
      services: [plumber, electrician],
      neighborhoods: [america]
    )
    create_published_profile(
      "+5547999997403",
      "Caio Centro",
      services: [electrician],
      neighborhoods: [centro]
    )
    suspended = create_published_profile(
      "+5547999997404",
      "Dora Suspensa",
      services: [electrician],
      all_city: true
    )
    suspended.user_account.update!(status: "suspended")
    create_draft_profile("+5547999997405", "Eva Rascunho", electrician)

    result = described_class.new(parser:).call(expression: "Trocar a fiação no América")

    expect(result.professionals).to contain_exactly(all_city, exact_area)
    expect(result.matching_service_for(exact_area)).to eq(electrician)
    expect(result.related_services).to include(plumber)
    expect(parser).to have_received(:call).with(
      expression: "Trocar a fiação no América",
      default_location: have_attributes(state_code: "SC", city: "Joinville")
    )
  end

  it "treats a location without a neighborhood as all Joinville and returns no matches without services" do
    profile = create_published_profile(
      "+5547999997406",
      "Fábio Específico",
      services: [electrician],
      neighborhoods: [centro]
    )

    allow(parser).to receive(:call).and_return(
      LlmSearchParser::Criteria.new(
        service_ids: [electrician.id],
        locations: [LlmSearchParser::Location.new(city_code: "4209102", state_code: "SC", city: "Joinville", neighborhood_code: nil)],
        keywords: [],
        normalized_request: "Eu preciso de eletricista em Joinville."
      )
    )
    all_city_result = described_class.new(parser:).call(expression: "Eletricista em Joinville")
    expect(all_city_result.professionals).to contain_exactly(profile)

    allow(parser).to receive(:call).and_return(
      LlmSearchParser::Criteria.new(
        service_ids: [],
        locations: [LlmSearchParser::Location.new(city_code: "4209102", state_code: "SC", city: "Joinville", neighborhood_code: nil)],
        keywords: [],
        normalized_request: nil
      )
    )
    unmatched = described_class.new(parser:).call(expression: "Algo fora do catálogo")
    expect(unmatched.professionals).to be_empty
  end

  it "uses the parser city instead of the selected default city" do
    curitiba_area = create_location_neighborhood(
      code: "4106902020",
      name: "Batel Busca",
      city: curitiba_city
    )
    joinville_profile = create_published_profile(
      "+5547999997420",
      "Profissional Joinville",
      services: [electrician],
      all_city: true
    )
    curitiba_profile = create_published_profile(
      "+5541999997421",
      "Profissional Curitiba",
      services: [electrician],
      neighborhoods: [curitiba_area]
    )
    allow(parser).to receive(:call).and_return(
      LlmSearchParser::Criteria.new(
        service_ids: [electrician.id],
        locations: [
          LlmSearchParser::Location.new(
            city_code: curitiba_city.code,
            state_code: "PR",
            city: "Curitiba",
            neighborhood_code: nil
          )
        ],
        keywords: [],
        normalized_request: "Eu preciso de eletricista em Curitiba."
      )
    )

    result = described_class.new(parser:).call(
      expression: "Eletricista em Curitiba",
      default_location: {city_code: joinville_city.code}
    )

    expect(result.professionals).to contain_exactly(curitiba_profile)
    expect(result.professionals).not_to include(joinville_profile)
  end

  it "searches controlled service and city filters without calling the LLM parser" do
    profile = create_published_profile(
      "+5547999997409",
      "Gabi Busca Manual",
      services: [electrician],
      neighborhoods: [centro]
    )

    result = described_class.new(parser:).call_with_filters(
      service_id: electrician.id,
      city_code: joinville_city.code
    )

    expect(result.professionals).to contain_exactly(profile)
    expect(result.criteria).to eq(
      LlmSearchParser::Criteria.new(
        service_ids: [electrician.id],
        locations: [
          LlmSearchParser::Location.new(
            city_code: "4209102",
            state_code: "SC",
            city: "Joinville",
            neighborhood_code: nil
          )
        ],
        keywords: [],
        normalized_request: nil
      )
    )
    expect(parser).not_to have_received(:call)
  end

  it "rejects uncontrolled structured filters" do
    search = described_class.new(parser:)

    expect {
      search.call_with_filters(service_id: "not-a-service", city_code: joinville_city.code)
    }.to raise_error(described_class::InvalidInput) do |error|
      expect(error.field_errors).to eq(service_id: ["selecione um serviço disponível"])
    end
    expect {
      search.call_with_filters(service_id: electrician.id, city_code: "4106902")
    }.to raise_error(described_class::InvalidInput) do |error|
      expect(error.field_errors.keys).to contain_exactly(:city_code)
    end
  end

  it "unions parsed services and uses their parser order for each card's matching service" do
    electrician_profile = create_published_profile(
      "+5547999997407",
      "Ana Eletricista",
      services: [electrician],
      all_city: true
    )
    plumber_profile = create_published_profile(
      "+5547999997408",
      "Beto Encanador",
      services: [plumber],
      all_city: true
    )
    allow(parser).to receive(:call).and_return(
      LlmSearchParser::Criteria.new(
        service_ids: [plumber.id, electrician.id],
        locations: [LlmSearchParser::Location.new(city_code: "4209102", state_code: "SC", city: "Joinville", neighborhood_code: nil)],
        keywords: [],
        normalized_request: "Eu preciso de encanador ou eletricista."
      )
    )

    result = described_class.new(parser:).call(expression: "Encanador ou eletricista")

    expect(result.professionals).to contain_exactly(electrician_profile, plumber_profile)
    expect(result.matching_service_for(electrician_profile)).to eq(electrician)
    expect(result.matching_service_for(plumber_profile)).to eq(plumber)
  end

  it "maps parser and pagination errors to the public expression field" do
    allow(parser).to receive(:call).and_raise(LlmSearchParser::LocationUnsupported)

    expect { described_class.new(parser:).call(expression: "Pintor em Curitiba") }
      .to raise_error(described_class::InvalidInput) do |error|
        expect(error.field_errors).to have_key(:expression)
      end
    expect { described_class.new(parser:).call(expression: "Pintor", page: 0, per_page: 51) }
      .to raise_error(described_class::InvalidInput) do |error|
        expect(error.field_errors.keys).to contain_exactly(:page, :per_page)
      end
  end

  it "keeps service and neighborhood lookups backed by their search indexes" do
    connection = ActiveRecord::Base.connection

    expect(
      connection.index_exists?(
        :professional_profile_services,
        %i[service_id professional_profile_revision_id],
        name: "idx_revision_services_service_revision"
      )
    ).to be(true)
    expect(
      connection.index_exists?(
        :professional_profile_service_areas,
        %i[neighborhood_code professional_profile_revision_id],
        name: "idx_revision_service_areas_neighborhood_revision"
      )
    ).to be(true)
  end

  it "orders lexicographically by explicit coverage, approved evidence, snapshot time, and UUID" do
    explicit_area = create_published_profile(
      "+5547999997410",
      "Área explícita",
      services: [electrician],
      neighborhoods: [america],
      reviewed_at: 30.days.ago
    )
    identity = create_published_profile(
      "+5547999997411",
      "Identidade aprovada",
      services: [electrician],
      all_city: true,
      reviewed_at: 20.days.ago
    )
    identity.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      public_label: ModerationDecision::IDENTITY_LABEL,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago,
      verified_at: 1.day.ago
    )
    portfolio = create_published_profile(
      "+5547999997412",
      "Portfólio aprovado",
      services: [electrician],
      all_city: true,
      reviewed_at: 10.days.ago
    )
    create_portfolio_item(portfolio)
    relationship = create_published_profile(
      "+5547999997413",
      "Relação aprovada",
      services: [electrician],
      all_city: true,
      reviewed_at: 5.days.ago
    )
    partner = create_published_profile(
      "+5547999997414",
      "Parceiro público",
      services: [plumber],
      all_city: true
    )
    create_public_relationship(relationship, partner)
    recent = create_published_profile(
      "+5547999997415",
      "Snapshot recente",
      services: [electrician],
      all_city: true,
      reviewed_at: 1.day.ago
    )
    recent.verification_requests.create!(
      verification_type: "identity",
      status: "pending_review",
      submitted_at: Time.current
    )
    create_portfolio_item(recent, deleted: true)
    create_unreviewed_relationship(recent, partner)
    tied_reviewed_at = 40.days.ago
    tied = [
      create_published_profile(
        "+5547999997416",
        "Empate A",
        services: [electrician],
        all_city: true,
        reviewed_at: tied_reviewed_at
      ),
      create_published_profile(
        "+5547999997417",
        "Empate B",
        services: [electrician],
        all_city: true,
        reviewed_at: tied_reviewed_at
      )
    ].sort_by(&:id)

    result = described_class.new(parser:).call(expression: "Eletricista no América")

    expect(result.professionals.to_a).to eq([
      explicit_area,
      identity,
      portfolio,
      recent,
      relationship,
      *tied
    ])
  end

  private

  def create_service(name, slug, aliases, order)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Serviço residencial para busca.",
      aliases:,
      is_active: true,
      sort_order: order
    )
  end

  def create_published_profile(
    phone,
    name,
    services:,
    all_city: false,
    neighborhoods: [],
    reviewed_at: Time.current
  )
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name, whatsapp_e164: phone)
    revision = profile.working_revision
    services.each_with_index do |service, index|
      revision.professional_profile_services.create!(service:, is_primary: index.zero?)
    end
    if all_city
      revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    else
      neighborhoods.each do |neighborhood|
        revision.update!(coverage_city: neighborhood.city, covers_whole_city: false)
        revision.professional_profile_service_areas.create!(neighborhood:)
      end
    end
    make_profile_publicly_eligible(profile, revision:, reviewed_at:)
  end

  def create_portfolio_item(profile, deleted: false)
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "attached",
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
      processed_at: Time.current,
      attached_at: Time.current
    )
    profile.portfolio_items.create!(
      media_upload: upload,
      service: electrician,
      title: "Evidência profissional",
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at: Time.current,
      deleted_at: deleted ? Time.current : nil
    )
  end

  def create_public_relationship(profile, partner)
    ProfessionalRelationship.create!(
      initiator_professional: profile,
      recipient_professional: partner,
      relationship_type: "recommendation",
      status: "accepted",
      responded_at: Time.current
    )
  end

  def create_unreviewed_relationship(profile, partner)
    ProfessionalRelationship.create!(
      initiator_professional: profile,
      recipient_professional: partner,
      relationship_type: "worked_together",
      status: "accepted",
      responded_at: Time.current
    )
  end

  def create_draft_profile(phone, name, service)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name)
    profile.working_revision.professional_profile_services.create!(service:, is_primary: true)
    profile
  end
end
