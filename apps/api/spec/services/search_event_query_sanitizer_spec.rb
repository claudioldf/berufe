# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchEventQuerySanitizer do
  it "retains a short service-like normalized term" do
    raw_term = "Conserto de torneira"

    expect(described_class.new.call(raw_term:, normalized_term: PublicSearchText.normalize(raw_term)))
      .to eq("conserto de torneira")
  end

  [
    "ana@example.com",
    "+55 (47) 99999-1234",
    "https://example.com/servico",
    "portfolio.profissional",
    "Meu nome é Ana Souza",
    "telefone para contato 47999991234",
    "Preciso explicar aqui todos os detalhes do problema da minha casa"
  ].each do |sensitive_term|
    it "does not retain clearly sensitive or note-like input: #{sensitive_term}" do
      raw_term = sensitive_term

      expect(described_class.new.call(raw_term:, normalized_term: PublicSearchText.normalize(raw_term))).to be_nil
    end
  end
end
