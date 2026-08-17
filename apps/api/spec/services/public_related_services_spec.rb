# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicRelatedServices do
  let!(:category) do
    ServiceCategory.create!(
      name: "Serviços relacionados",
      slug: "servicos-relacionados",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end

  it "returns at most three deterministic suggestions closest to an unmatched term" do
    electrician = create_service("Eletricista", "relacionado-eletricista", ["eletrica"], 4)
    create_service("Azulejista", "relacionado-azulejista", ["azulejo"], 0)
    create_service("Encanador", "relacionado-encanador", ["hidraulica"], 1)
    create_service("Pintor", "relacionado-pintor", ["pintura"], 2)

    suggestions = described_class.new.call(
      normalized_term: "eletricsta",
      active_services: Service.publicly_active.includes(:category).ordered.to_a
    )

    expect(suggestions).to have_attributes(length: 3)
    expect(suggestions.first).to eq(electrician)
  end

  it "prioritizes the resolved service category and excludes the resolved service" do
    other_category = ServiceCategory.create!(
      name: "Outra categoria relacionada",
      slug: "outra-categoria-relacionada",
      icon: "i-lucide-hammer",
      is_active: true,
      sort_order: 1
    )
    resolved = create_service("Eletricista principal", "relacionado-principal", [], 0)
    same_category = create_service("Encanador próximo", "relacionado-proximo", [], 10)
    other = Service.create!(
      category: other_category,
      name: "Pintor distante",
      slug: "relacionado-distante",
      icon: "i-lucide-paintbrush",
      description: "Serviço residencial controlado.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )

    suggestions = described_class.new.call(
      normalized_term: "eletricista principal",
      active_services: [resolved, other, same_category],
      resolved_service: resolved
    )

    expect(suggestions).to eq([same_category, other])
  end

  private

  def create_service(name, slug, aliases, order)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Serviço residencial controlado.",
      aliases:,
      is_active: true,
      sort_order: order
    )
  end
end
