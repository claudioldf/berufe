# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ibge::LocationSource do
  it "keeps cities from states for which IBGE publishes no neighborhood archive" do
    logger = instance_double(ActiveSupport::Logger, warn: nil)
    source = described_class.new(logger:)
    allow(source).to receive(:get).and_raise(described_class::ResourceNotFound)

    expect(source.send(:fetch_neighborhoods, "DF", Set["5300108"])).to eq([])
    expect(source.missing_neighborhood_archives).to eq(["DF"])
    expect(logger).to have_received(:warn).with(
      "O IBGE não publicou arquivo de bairros para DF; cidades importadas sem bairros."
    )
  end
end
