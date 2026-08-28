# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llm::FakeStrategy do
  it "uses the first explicit city and that city's neighborhoods" do
    category = ServiceCategory.create!(
      name: "Busca fake",
      slug: "busca-fake",
      icon: "i-lucide-search",
      is_active: true,
      sort_order: 0
    )
    painter = Service.create!(
      category:,
      name: "Pintor fake",
      slug: "pintor-fake",
      icon: "i-lucide-paintbrush",
      description: "Pintura residencial.",
      aliases: ["pintura fake"],
      is_active: true,
      sort_order: 0
    )
    joinville_neighborhood = create_location_neighborhood(
      code: "4209102021",
      name: "América Fake"
    )
    curitiba_neighborhood = create_location_neighborhood(
      code: "4106902021",
      name: "Batel Fake",
      city: curitiba_city
    )

    response = described_class.new.call(
      expression: "Pintor fake no Batel Fake em Curitiba ou Joinville",
      prompt: "",
      schema: {},
      services: [painter],
      neighborhoods: [joinville_neighborhood],
      default_location: SupportedSearchLocations::FALLBACK
    )

    expect(response.payload.fetch("locations")).to eq([
      {
        "state_code" => "PR",
        "city" => "Curitiba",
        "neighborhood" => curitiba_neighborhood.name
      }
    ])
  end
end
