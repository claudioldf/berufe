# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public catalog policies" do
  let!(:active_category) { create_category(name: "Instalações", slug: "instalacoes") }
  let!(:inactive_category) { create_category(name: "Oculta", slug: "oculta", active: false, order: 1) }
  let!(:active_service) { create_service(category: active_category, name: "Eletricista", slug: "eletricista") }
  let!(:inactive_service) { create_service(category: active_category, name: "Inativo", slug: "inativo", active: false, order: 1) }
  let!(:hidden_category_service) { create_service(category: inactive_category, name: "Oculto", slug: "oculto", order: 2) }
  let!(:active_neighborhood) { create_neighborhood(code: "america", name: "América") }
  let!(:inactive_neighborhood) { create_neighborhood(code: "atiradores", name: "Atiradores", active: false, order: 1) }

  it "returns only active approved public data for every kind of visitor" do
    actors = [
      nil,
      create_account(phone: "+5547999993001"),
      create_account(phone: "+5547999993002", role: "admin"),
      create_account(phone: "+5547999993003", status: "suspended")
    ]

    actors.each do |actor|
      expect(ServiceCategoryPolicy::Scope.new(actor, ServiceCategory).resolve).to contain_exactly(active_category)
      expect(ServicePolicy::Scope.new(actor, Service).resolve).to contain_exactly(active_service)
      expect(NeighborhoodPolicy::Scope.new(actor, Neighborhood).resolve).to contain_exactly(active_neighborhood)
    end
  end

  it "denies direct public visibility as soon as an entry or its category is inactive" do
    expect(ServiceCategoryPolicy.new(nil, active_category).show?).to be(true)
    expect(ServiceCategoryPolicy.new(nil, inactive_category).show?).to be(false)
    expect(ServicePolicy.new(nil, active_service).show?).to be(true)
    expect(ServicePolicy.new(nil, inactive_service).show?).to be(false)
    expect(ServicePolicy.new(nil, hidden_category_service).show?).to be(false)
    expect(NeighborhoodPolicy.new(nil, active_neighborhood).show?).to be(true)
    expect(NeighborhoodPolicy.new(nil, inactive_neighborhood).show?).to be(false)
  end

  private

  def create_account(phone:, role: "professional", status: "active")
    UserAccount.create!(phone_e164: phone, role:, status:)
  end

  def create_category(name:, slug:, active: true, order: 0)
    ServiceCategory.create!(name:, slug:, icon: "i-lucide-wrench", is_active: active, sort_order: order)
  end

  def create_service(category:, name:, slug:, active: true, order: 0)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Descrição pública.",
      aliases: [],
      is_active: active,
      sort_order: order
    )
  end

  def create_neighborhood(code:, name:, active: true, order: 0)
    Neighborhood.create!(
      code:,
      name:,
      state_code: "SC",
      city_code: "Joinville",
      is_active: active,
      sort_order: order
    )
  end
end
