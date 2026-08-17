# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Catalog models", type: :model do
  def create_category(attributes = {})
    ServiceCategory.create!({
      name: "Instalações e reparos",
      slug: "instalacoes",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    }.merge(attributes))
  end

  def create_service(category:, **attributes)
    Service.create!({
      category:,
      name: "Eletricista",
      slug: "eletricista",
      icon: "i-lucide-zap",
      description: "Instalações e reparos elétricos.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    }.merge(attributes))
  end

  it "keeps category and service slugs immutable" do
    category = create_category
    service = create_service(category:)

    expect(category.update(slug: "outra-categoria")).to be(false)
    expect(service.update(slug: "outro-servico")).to be(false)
    expect(category.errors[:slug]).to be_present
    expect(service.errors[:slug]).to be_present
  end

  it "returns only services whose service and category are active" do
    active_category = create_category
    inactive_category = create_category(name: "Acabamentos", slug: "acabamentos", is_active: false, sort_order: 1)
    visible = create_service(category: active_category)
    create_service(category: active_category, name: "Encanador", slug: "encanador", is_active: false, sort_order: 1)
    create_service(category: inactive_category, name: "Pintor", slug: "pintor", sort_order: 2)

    expect(Service.publicly_active).to contain_exactly(visible)
  end

  it "keeps neighborhood codes immutable and orders active entries deterministically" do
    second = Neighborhood.create!(code: "america", state_code: "SC", city_code: "Joinville", name: "América", is_active: true, sort_order: 1)
    first = Neighborhood.create!(code: "adhemar-garcia", state_code: "SC", city_code: "Joinville", name: "Adhemar Garcia", is_active: true, sort_order: 0)
    Neighborhood.create!(code: "atiradores", state_code: "SC", city_code: "Joinville", name: "Atiradores", is_active: false, sort_order: 2)

    expect(Neighborhood.active.ordered).to eq([first, second])
    expect(first.update(code: "novo-codigo")).to be(false)
    expect(first.errors[:code]).to be_present
  end

  it "uses the documented UUID, text-key, smallint, and UTC timestamp database types" do
    connection = ActiveRecord::Base.connection
    category_columns = connection.columns(:service_categories).index_by(&:name)
    service_columns = connection.columns(:services).index_by(&:name)
    neighborhood_columns = connection.columns(:neighborhoods).index_by(&:name)

    expect(category_columns.fetch("id").sql_type).to eq("uuid")
    expect(service_columns.fetch("id").sql_type).to eq("uuid")
    expect(service_columns.fetch("sort_order").sql_type).to eq("smallint")
    expect(connection.primary_key(:neighborhoods)).to eq("code")
    expect(neighborhood_columns.fetch("code").sql_type).to eq("text")
    expect(neighborhood_columns.fetch("state_code").sql_type).to eq("character varying(2)")
    expect(neighborhood_columns.fetch("sort_order").sql_type).to eq("smallint")
    expect(neighborhood_columns.fetch("created_at").sql_type).to include("timestamp", "with time zone")
  end
end
