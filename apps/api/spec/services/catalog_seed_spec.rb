# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe CatalogSeed, type: :service do
  let(:catalog) do
    {
      categories: [
        {id: "instalacoes", name: "Instalações", icon: "i-lucide-wrench"}
      ],
      services: [
        {
          id: "svc-eletricista",
          name: "Eletricista",
          slug: "eletricista",
          category: "instalacoes",
          icon: "i-lucide-zap",
          description: "Instalações elétricas.",
          aliases: ["elétrica"]
        }
      ],
      neighborhoods: [
        {code: "all", name: "Toda Joinville", stateCode: "SC", city: "Joinville"},
        {code: "america", name: "América", stateCode: "SC", city: "Joinville"},
        {code: "atiradores", name: "Atiradores", stateCode: "SC", city: "Joinville"}
      ]
    }
  end

  it "seeds stable service records once and preserves later edits" do
    Tempfile.create(["catalog", ".json"]) do |file|
      file.write(JSON.generate(catalog))
      file.flush
      seed = described_class.new(path: file.path)

      seed.call
      Service.find_by!(slug: "eletricista").update!(name: "Eletricista residencial")
      seed.call

      expect(ServiceCategory.count).to eq(1)
      expect(Service.count).to eq(1)
      expect(Service.find_by!(slug: "eletricista")).to have_attributes(
        name: "Eletricista residencial",
        aliases: ["elétrica"],
        sort_order: 0
      )
    end
  end

  it "uses the configured catalog path when one is provided" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CATALOG_SEED_PATH").and_return("/tmp/approved-catalog.json")

    expect(described_class.default_path).to eq(Pathname("/tmp/approved-catalog.json"))
  end
end
