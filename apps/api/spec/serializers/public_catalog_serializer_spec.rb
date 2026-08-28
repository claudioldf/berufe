# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicCatalogSerializer do
  it "emits only the catalog fields approved for the existing public UI" do
    category = ServiceCategory.create!(
      name: "Instalações",
      slug: "instalacoes",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    service = Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
    serialized = described_class.new(categories: [category], services: [service]).as_json

    expect(serialized).to eq(
      categories: [{id: category.id, slug: "instalacoes", name: "Instalações", icon: "i-lucide-wrench"}],
      services: [{
        id: service.id,
        name: "Eletricista",
        slug: "eletricista",
        category_slug: "instalacoes",
        icon: "i-lucide-zap",
        description: "Instalações elétricas.",
        aliases: ["elétrica"]
      }],
      cities: []
    )
    expect(serialized.to_json).not_to include(
      "is_active",
      "sort_order",
      "category_id",
      "created_at",
      "updated_at"
    )
  end
end
