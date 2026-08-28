# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ibge::LocationImporter do
  subject(:import) { described_class.new.call(**payload) }

  let(:payload) do
    {
      states: [
        {code: 43, abbreviation: "rs", name: " Rio Grande do Sul "}
      ],
      cities: [
        {code: 4_314_902, state_code: 43, name: "Porto Alegre"}
      ],
      neighborhoods: [
        {code: 4_314_902_001, city_code: 4_314_902, name: " Centro Histórico "}
      ]
    }
  end

  it "normalizes and idempotently imports the complete hierarchy" do
    expect { import }.to change(State, :count).by(1)
      .and change(City, :count).by(1)
      .and change(Neighborhood, :count).by(1)

    expect(import.to_h).to eq(states: 1, cities: 1, neighborhoods: 1)
    expect(State.find("43")).to have_attributes(abbreviation: "RS", name: "Rio Grande do Sul")
    expect(City.find("4314902")).to have_attributes(state_code: "43", slug: "porto-alegre")
    expect(Neighborhood.find("4314902001")).to have_attributes(
      city_code: "4314902",
      name: "Centro Histórico"
    )
  end

  it "rejects broken references before writing any rows" do
    payload[:neighborhoods][0][:city_code] = "4106902"

    expect { import }.to raise_error(ArgumentError, /referencia uma cidade ausente/)
    expect([State.where(code: "43").count, City.where(code: "4314902").count, Neighborhood.count]).to eq([0, 0, 0])
  end
end
