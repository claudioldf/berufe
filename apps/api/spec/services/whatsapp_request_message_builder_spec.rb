# frozen_string_literal: true

require "rails_helper"

RSpec.describe WhatsappRequestMessageBuilder do
  it "personalizes a safe LLM-normalized search request" do
    expect(
      described_class.call(
        professional_name: "Ana Souza",
        service_name: "Instalação elétrica",
        state_code: "SC",
        city: "Joinville",
        normalized_request: "Eu preciso trocar a fiação da cozinha.",
        search_context: true
      )
    ).to eq(
      "Olá, Ana Souza! Encontrei seu perfil na Berufe. Eu preciso trocar a fiação da cozinha."
    )
  end

  it "builds a first-person structured fallback with and without a location" do
    expect(
      described_class.call(
        professional_name: "Ana Souza",
        service_name: "Eletricista",
        state_code: "SC",
        city: "Joinville",
        search_context: true
      )
    ).to eq(
      "Olá, Ana Souza! Encontrei seu perfil na Berufe. Eu preciso de eletricista em Joinville, SC."
    )
    expect(
      described_class.call(
        professional_name: "Ana Souza",
        service_name: "Eletricista",
        search_context: true
      )
    ).to eq(
      "Olá, Ana Souza! Encontrei seu perfil na Berufe. Eu preciso de eletricista."
    )
  end

  it "rejects unsafe normalized requests and uses controlled structured values" do
    unsafe_requests = [
      "Olá, eu preciso de eletricista.",
      "Eu preciso de eletricista na Rua das Flores, 100.",
      "Eu preciso de eletricista; meu telefone é 47999991111.",
      "Eu preciso falar com a Berufe.",
      "Preciso de eletricista.",
      "Eu preciso de #{"x" * 230}."
    ]

    unsafe_requests.each do |request|
      expect(
        described_class.call(
          professional_name: "Ana Souza",
          service_name: "Eletricista",
          state_code: "SC",
          city: "Joinville",
          normalized_request: request,
          search_context: true
        )
      ).to end_with("Eu preciso de eletricista em Joinville, SC.")
    end
  end

  it "preserves the existing direct-profile message" do
    expect(
      described_class.call(
        professional_name: "Ana Souza",
        service_name: "Eletricista",
        normalized_request: "Eu preciso trocar a fiação.",
        search_context: false
      )
    ).to eq("Olá! Vi seu perfil na Berufe para Eletricista.")
  end
end
