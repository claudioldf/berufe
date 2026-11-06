# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportedSearchLocations do
  subject(:locations) { described_class.new }

  before { described_class.reset! }

  after { described_class.reset! }

  def create_city(code:, name:, state: santa_catarina_state)
    City.create!(code:, name:, slug: name.parameterize, state:)
  end

  it "loads the cities once while they do not change" do
    locations.all
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].match?(/FROM "cities"/) && payload[:sql].exclude?("count(*)") }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      locations.all
      locations.find_by_code(city_code: SupportedSearchLocations::FALLBACK.city_code)
    end

    expect(queries).to be_empty
  end

  it "rebuilds the index when a city is added" do
    expect(locations.find_by_code(city_code: "4205407")).to be_nil

    create_city(code: "4205407", name: "Florianópolis")

    expect(locations.find_by_code(city_code: "4205407")).to have_attributes(city: "Florianópolis")
  end

  it "finds cities by route and by unambiguous name" do
    expect(locations.find_by_route(state_slug: "SC", city_slug: "joinville")).to eq(SupportedSearchLocations::FALLBACK)
    expect(locations.find(state_code: "sc", city: "JOINVILLE")).to eq(SupportedSearchLocations::FALLBACK)
    expect(locations.find(state_code: "PR", city: "Joinville")).to be_nil
  end

  describe "#named_in" do
    before do
      create_city(code: "4216602", name: "São José")
      create_city(code: "3549904", name: "São José dos Campos", state: parana_state)
    end

    it "matches whole-word city names regardless of accents and punctuation" do
      names = locations.named_in("Eletricista em sao jose/SC, perto de Joinville").map { |_, name| name }

      expect(names).to contain_exactly("sao jose", "joinville")
    end

    it "matches multi-word names and does not match partial words" do
      names = locations.named_in("pintor em são josé dos campos").map { |_, name| name }

      expect(names).to contain_exactly("sao jose", "sao jose dos campos")
      expect(locations.named_in("joinvillense")).to be_empty
    end
  end

  it "changes the fingerprint when the cities change" do
    first = locations.fingerprint
    create_city(code: "4205407", name: "Florianópolis")

    expect(locations.fingerprint).not_to eq(first)
    expect(first).to match(/\A[0-9a-f]{64}\z/)
  end
end
