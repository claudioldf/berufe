# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llm::OpenaiStrategy do
  it "uses stateless Responses API structured output and returns safe metadata" do
    content = double(text: '{"service_ids":[],"locations":[],"keywords":[],"normalized_request":null}')
    output = double(content: [content])
    reasoning = double
    token_details = double(cached_tokens: 12)
    usage = double(input_tokens: 80, input_tokens_details: token_details, output_tokens: 20)
    response = double(output: [reasoning, output], usage:, _request_id: "req_openai")
    responses = double
    client = double(responses:)
    allow(responses).to receive(:create).and_return(response)
    schema = {
      type: "object",
      properties: {},
      required: [],
      additionalProperties: false
    }

    result = described_class.new(model: "gpt-5-mini", client:).call(
      expression: "Preciso de um eletricista",
      prompt: "Interprete o pedido",
      schema:,
      services: [],
      neighborhoods: []
    )

    expect(responses).to have_received(:create).with(
      model: "gpt-5-mini",
      store: false,
      input: [
        {role: :system, content: "Interprete o pedido"},
        {role: :user, content: "Preciso de um eletricista"}
      ],
      text: {
        format: {
          type: :json_schema,
          name: "berufe_public_search",
          strict: true,
          schema:
        }
      },
      max_output_tokens: 800
    )
    expect(result).to have_attributes(
      payload: {"service_ids" => [], "locations" => [], "keywords" => [], "normalized_request" => nil},
      provider_request_id: "req_openai",
      input_tokens: 80,
      cached_input_tokens: 12,
      output_tokens: 20
    )
    expect(result.latency_ms).to be_a(Integer)
  end

  it "preserves provider rate limits and their retry delay" do
    responses = double
    client = double(responses:)
    error = OpenAI::Errors::RateLimitError.new(
      url: URI("https://api.openai.com/v1/responses"),
      status: 429,
      headers: {"retry-after" => "37"},
      body: {"error" => {"message" => "Rate limited"}},
      request: nil,
      response: nil
    )
    allow(responses).to receive(:create).and_raise(error)

    expect {
      described_class.new(model: "gpt-5-mini", client:).call(
        expression: "Preciso de um eletricista",
        prompt: "Interprete o pedido",
        schema: {},
        services: [],
        neighborhoods: []
      )
    }.to raise_error(Llm::Client::RateLimited) { |raised| expect(raised.retry_after).to eq(37) }
  end
end
