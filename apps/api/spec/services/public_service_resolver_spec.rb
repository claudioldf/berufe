# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicServiceResolver do
  let!(:category) { create_category("Instalações", "resolver-instalacoes", 0) }
  let!(:inactive_category) { create_category("Inativa", "resolver-inativa", 1, active: false) }
  let!(:electrician) do
    create_service(
      category:,
      name: "Eletricista",
      slug: "resolver-eletricista",
      aliases: ["elétrica", "tomada"],
      order: 0
    )
  end

  it "resolves an active service by exact normalized slug, name, or controlled alias" do
    expect(described_class.new.call("resolver-eletricista").service).to eq(electrician)
    expect(described_class.new.call("  ELETRICISTA  ").service).to eq(electrician)
    expect(described_class.new.call("Elétrica!").service).to eq(electrician)
  end

  it "does not resolve partial, inactive-service, or inactive-category values" do
    inactive_service = create_service(
      category:,
      name: "Encanador inativo",
      slug: "resolver-encanador-inativo",
      aliases: ["canos"],
      order: 1,
      active: false
    )
    hidden_by_category = create_service(
      category: inactive_category,
      name: "Pintor oculto",
      slug: "resolver-pintor-oculto",
      aliases: ["pintura oculta"],
      order: 2
    )

    expect(described_class.new.call("eletri").service).to be_nil
    expect(described_class.new.call(inactive_service.slug).service).to be_nil
    expect(described_class.new.call(hidden_by_category.name).service).to be_nil
  end

  it "normalizes accents and punctuation into a bounded search value" do
    expect(PublicSearchText.normalize("  Ar-condicionado & Climatização  ")).to eq(
      "ar condicionado climatizacao"
    )
  end

  private

  def create_category(name, slug, order, active: true)
    ServiceCategory.create!(
      name:,
      slug:,
      icon: "i-lucide-wrench",
      is_active: active,
      sort_order: order
    )
  end

  def create_service(category:, name:, slug:, aliases:, order:, active: true)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Serviço residencial controlado.",
      aliases:,
      is_active: active,
      sort_order: order
    )
  end
end
