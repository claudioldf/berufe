# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SearchAuditIndexQuery do
  it "sorts lower result counts first by default" do
    now = Time.zone.parse("2026-08-25 15:00:00")
    higher = create_audit(
      prompt: "Muitos resultados",
      status: "completed",
      result_count: 8,
      created_at: now - 1.hour
    )
    zero = create_audit(
      prompt: "Nenhum resultado",
      status: "completed",
      result_count: 0,
      created_at: now - 2.hours
    )
    thin = create_audit(
      prompt: "Poucos resultados",
      status: "completed",
      result_count: 2,
      created_at: now - 3.hours
    )

    result = described_class.new(now: -> { now }).call

    expect(result.events.pluck(:id)).to eq([zero.id, thin.id, higher.id])
  end

  it "summarizes searched audits and prioritizes zero, rejected, thin, operational, and healthy rows" do
    now = Time.zone.parse("2026-08-25 15:00:00")
    healthy = create_audit(
      prompt: "Pintor no Centro",
      status: "completed",
      result_count: 8,
      created_at: now - 1.hour
    )
    operational = create_audit(
      prompt: "Pintor urgente",
      status: "provider_unavailable",
      result_count: 0,
      created_at: now - 2.hours
    )
    thin = create_audit(
      prompt: "Pintor no América",
      status: "completed",
      result_count: 2,
      created_at: now - 3.hours
    )
    rejected = create_audit(
      prompt: "Pintura muito específica",
      status: "response_rejected",
      result_count: 0,
      created_at: now - 4.hours
    )
    zero = create_audit(
      prompt: "Pintor para mural",
      status: "completed",
      result_count: 0,
      created_at: now - 5.hours
    )
    create_audit(
      prompt: "Pintor antigo",
      status: "completed",
      result_count: 0,
      created_at: now - 6.months - 1.minute
    )

    result = described_class.new(now: -> { now }).call(q: "pint", sort: "gaps")

    expect(result.events.pluck(:id)).to eq([zero.id, rejected.id, thin.id, operational.id, healthy.id])
    expect(result.summary).to eq(
      total: 5,
      zero_results: 1,
      not_understood: 1,
      thin_results: 1,
      operational_issue: 1,
      healthy: 1
    )
  end

  it "searches controlled interpretation fields and filters without changing summary counts" do
    now = Time.zone.parse("2026-08-25 15:00:00")
    matching = create_audit(
      prompt: "Preciso de ajuda",
      status: "completed",
      result_count: 1,
      created_at: now - 1.hour,
      service_name: "Eletricista",
      city: "Joinville",
      neighborhood_name: "América",
      normalized_request: "Eu preciso instalar uma tomada."
    )
    create_audit(
      prompt: "Consertar vazamento",
      status: "completed",
      result_count: 5,
      created_at: now - 2.hours,
      service_name: "Encanador",
      city: "Curitiba"
    )

    %w[eletricista joinville américa tomada].each do |query|
      result = described_class.new(now: -> { now }).call(q: query, outcome: "thin_results")
      expect(result.events.pluck(:id)).to eq([matching.id])
      expect(result.summary).to include(total: 1, thin_results: 1)
    end
  end

  it "validates analytical filters" do
    expect do
      described_class.new.call(q: "a" * 101, outcome: "unknown", sort: "oldest")
    end.to raise_error(described_class::Invalid) do |error|
      expect(error.field_errors.keys).to contain_exactly(:q, :outcome, :sort)
    end
  end

  it "uses the six-month default when the setting is absent in a running process" do
    now = Time.zone.parse("2026-08-25 15:00:00")
    settings = Rails.configuration.x.berufe.reporting
    allow(settings).to receive(:llm_search_audit_retention_months).and_return(nil)
    retained = create_audit(
      prompt: "Busca ainda auditável",
      status: "completed",
      result_count: 3,
      created_at: now - 5.months
    )
    create_audit(
      prompt: "Busca expirada",
      status: "completed",
      result_count: 3,
      created_at: now - 7.months
    )

    result = described_class.new(now: -> { now }).call

    expect(result.events.pluck(:id)).to eq([retained.id])
  end

  private

  def create_audit(
    prompt:,
    status:,
    result_count:,
    created_at:,
    service_name: "Pintor",
    city: "Joinville",
    neighborhood_name: nil,
    normalized_request: "Eu preciso de pintor."
  )
    SearchEvent.create!(
      input_prompt: prompt,
      raw_llm_response: '{"service_ids":[]}',
      parsed_response: {
        service_ids: [],
        services: [{id: SecureRandom.uuid, name: service_name}],
        locations: [
          {
            state_code: "SC",
            city:,
            neighborhood: neighborhood_name && {code: "bairro", name: neighborhood_name}
          }
        ],
        keywords: [],
        normalized_request:
      },
      audit_status: status,
      response_source: "provider",
      llm_adapter: "fake",
      llm_model: "gpt-5-mini",
      llm_prompt_digest: "a" * 64,
      city_code: joinville_city.code,
      result_count:,
      reportable: status == "completed",
      created_at:
    )
  end
end
