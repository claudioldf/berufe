# frozen_string_literal: true

require "rails_helper"

module JevResolverSpecSupport
  Response = Struct.new(:code, :body, :headers) do
    def [](name)
      headers[name]
    end
  end

  class FakeConnection
    attr_reader :requests

    def initialize(responses)
      @responses = responses
      @requests = []
    end

    def request(request)
      @requests << request
      (@responses.size > 1) ? @responses.shift : @responses.first
    end
  end

  class FakeHttp
    attr_reader :connection, :options

    def initialize(responses)
      @connection = FakeConnection.new(responses)
    end

    def start(_host, _port, **options)
      @options = options
      yield connection
    end
  end

  class TimeoutHttp
    def start(*, **)
      raise Net::ReadTimeout
    end
  end
end

RSpec.describe SearchResolvers::Jev do
  let!(:category) do
    ServiceCategory.create!(name: "Jev", slug: "jev", icon: "i-lucide-zap", is_active: true, sort_order: 0)
  end
  let!(:electrician) do
    Service.create!(
      category:, name: "Eletricista jev", slug: "eletricista-jev", icon: "i-lucide-zap",
      description: "Instalações elétricas.", aliases: ["elétrica"], is_active: true, sort_order: 0
    )
  end
  let!(:plumber) do
    Service.create!(
      category:, name: "Encanador jev", slug: "encanador-jev", icon: "i-lucide-droplet",
      description: "Vazamentos e canos.", aliases: [], is_active: true, sort_order: 1
    )
  end
  let!(:america) { create_location_neighborhood(code: "4209102012", name: "América Jev") }
  let!(:batel) do
    create_location_neighborhood(code: "4106902012", name: "Batel Jev", city: curitiba_city)
  end
  let(:services) { [electrician, plumber] }
  let(:default_location) do
    LlmSearchParser::Location.new(
      city_code: joinville_city.code, state_code: "SC", city: "Joinville", neighborhood_code: nil
    )
  end
  let(:neighborhoods) { Neighborhood.where(city_code: joinville_city.code).ordered.to_a }

  def answers(wants_service: 0.97, service: nil, mentions_city: 0.02, city: nil, neighborhood: nil)
    result = {
      "wants_service" => {"type" => "noul", "noul" => wants_service},
      "mentions_city" => {"type" => "noul", "noul" => mentions_city}
    }
    result["service"] = service || choice(electrician.slug, 0.93, electrician.slug => 0.93, plumber.slug => 0.07)
    result["city"] = city || choice(joinville_city.code, 0.9, joinville_city.code => 0.9, "outra_cidade" => 0.1)
    result["neighborhood"] = neighborhood || choice("nenhum", 0.95, "nenhum" => 0.95, america.code => 0.05)
    result
  end

  def choice(selected, confidence, probabilities)
    {"type" => "choice", "choice" => selected, "confidence" => confidence, "probabilities" => probabilities}
  end

  def json_response(answers, code: 200, headers: {})
    body = {"model" => "jev-1.14.0", "answers" => answers, "usage" => {"input_tokens" => 120, "output_tokens" => 30}}
    JevResolverSpecSupport::Response.new(code.to_s, JSON.generate(body), headers)
  end

  def resolver(*responses, **options)
    @http = JevResolverSpecSupport::FakeHttp.new(responses)
    described_class.new(
      api_key: "typesafe-secret", model: "jev-latest", timeout_seconds: 3,
      min_confidence: 0.5, secondary_probability: 0.25, http: @http, **options
    )
  end

  def resolve(resolver, expression = "Preciso de um eletricista", neighborhoods: self.neighborhoods)
    resolver.call(expression:, services:, neighborhoods:, default_location:)
  end

  it "labels audits and cache entries with the JEV adapter and requested model" do
    expect(resolver(json_response(answers))).to have_attributes(adapter: "jev", model: "jev-latest")
  end

  it "maps the answers to the shared payload and reports usage" do
    response = resolve(resolver(json_response(answers(
      neighborhood: choice(america.code, 0.9, america.code => 0.9, "nenhum" => 0.1)
    ))))

    expect(response.payload).to eq(
      "service_ids" => [electrician.id],
      "locations" => [{"state_code" => "SC", "city" => "Joinville", "neighborhood" => "América Jev"}],
      "keywords" => [],
      "normalized_request" => "Eu preciso de eletricista jev em América Jev, SC."
    )
    expect(response).to have_attributes(
      provider_request_id: nil, input_tokens: 120, output_tokens: 30, cached_input_tokens: nil
    )
    expect(JSON.parse(response.raw_response).first.fetch("answers")).to include("service")
  end

  it "sends a bearer-authenticated System One request with catalog-keyed criteria" do
    resolve(resolver(json_response(answers)), "Preciso de um eletricista")

    request = @http.connection.requests.sole
    body = JSON.parse(request.body)
    expect(request["Authorization"]).to eq("Bearer typesafe-secret")
    expect(request.path).to eq("/v1/systemone")
    expect(body).to include("model" => "jev-latest", "state" => "Preciso de um eletricista")
    expect(body.fetch("questions").keys).to eq(%w[wants_service service mentions_city city neighborhood])
    expect(body.dig("questions", "service", "criteria", electrician.slug)).to eq(
      "nome" => "Eletricista jev", "aliases" => ["elétrica"], "descricao" => "Instalações elétricas."
    )
    expect(body.dig("questions", "neighborhood", "criteria")).to include(america.code => "América Jev", "nenhum" => anything)
    expect(@http.options).to include(use_ssl: true, open_timeout: 3.0, read_timeout: 3.0)
  end

  it "adds services above the secondary probability, best first, and ignores the rest" do
    service_answer = choice(plumber.slug, 0.6, plumber.slug => 0.6, electrician.slug => 0.3, "extra" => 0.1)

    payload = resolve(resolver(json_response(answers(service: service_answer)))).payload

    expect(payload.fetch("service_ids")).to eq([plumber.id, electrician.id])
  end

  it "returns no services when the request is not for a service or the answer is not confident enough" do
    not_a_service = resolve(resolver(json_response(answers(wants_service: 0.1)))).payload
    unsure = resolve(resolver(json_response(answers(
      service: choice(electrician.slug, 0.3, electrician.slug => 0.4, plumber.slug => 0.6)
    )))).payload

    expect(not_a_service).to include("service_ids" => [], "normalized_request" => nil)
    expect(unsure).to include("service_ids" => [], "normalized_request" => nil)
  end

  it "ignores a neighborhood answer that is not confident enough" do
    payload = resolve(resolver(json_response(answers(
      neighborhood: choice(america.code, 0.3, america.code => 0.4, "nenhum" => 0.6)
    )))).payload

    expect(payload.dig("locations", 0, "neighborhood")).to be_nil
  end

  it "marks a city outside the supported list so the parser rejects it" do
    payload = resolve(resolver(json_response(answers(
      mentions_city: 0.99,
      city: choice("outra_cidade", 0.9, "outra_cidade" => 0.9, joinville_city.code => 0.1)
    )))).payload

    expect(payload.fetch("locations")).to eq(
      [{"state_code" => nil, "city" => described_class::UNSUPPORTED_CITY, "neighborhood" => nil}]
    )
    expect {
      LlmSearchParser.new(resolver: resolver(json_response(answers(
        mentions_city: 0.99,
        city: choice("outra_cidade", 0.9, "outra_cidade" => 0.9, joinville_city.code => 0.1)
      )))).call(expression: "Eletricista em Marte")
    }.to raise_error(LlmSearchParser::LocationUnsupported)
  end

  it "resolves another supported city with a second neighborhood-only request" do
    first = json_response(answers(
      mentions_city: 0.99,
      city: choice(curitiba_city.code, 0.9, curitiba_city.code => 0.9, joinville_city.code => 0.1)
    ))
    second = json_response({"neighborhood" => choice(batel.code, 0.9, batel.code => 0.9, "nenhum" => 0.1)})

    response = resolve(resolver(first, second))

    expect(response.payload.fetch("locations")).to eq(
      [{"state_code" => "PR", "city" => "Curitiba", "neighborhood" => "Batel Jev"}]
    )
    expect(response.payload.fetch("normalized_request")).to eq("Eu preciso de eletricista jev em Batel Jev, PR.")
    follow_up = JSON.parse(@http.connection.requests.last.body)
    expect(follow_up.fetch("questions").keys).to eq(["neighborhood"])
    expect(follow_up.dig("questions", "neighborhood", "criteria")).to include(batel.code => "Batel Jev")
    expect(response).to have_attributes(input_tokens: 240, output_tokens: 60)
    expect(JSON.parse(response.raw_response).size).to eq(2)
  end

  it "changes the prompt digest when the catalog changes" do
    jev = resolver(json_response(answers))
    first = jev.prompt_digest(services:, neighborhoods:, default_location:)
    electrician.update!(description: "Outra descrição.")

    expect(jev.prompt_digest(services:, neighborhoods:, default_location:)).not_to eq(first)
    expect(first).to match(/\A[0-9a-f]{64}\z/)
  end

  describe "provider failures" do
    it "maps rate limits and overload, honoring Retry-After" do
      expect { resolve(resolver(json_response({}, code: 429, headers: {"Retry-After" => "42"}))) }
        .to raise_error(Llm::Client::RateLimited) { |error| expect(error.retry_after).to eq(42) }
      expect { resolve(resolver(json_response({}, code: 529))) }
        .to raise_error(Llm::Client::RateLimited) { |error| expect(error.retry_after).to eq(60) }
    end

    it "treats rejected requests and server errors as unavailable" do
      [400, 401, 422, 500].each do |code|
        expect { resolve(resolver(json_response({}, code:))) }
          .to raise_error(Llm::Client::Unavailable, "JEV returned HTTP #{code}")
      end
    end

    it "treats network failures as unavailable" do
      jev = described_class.new(
        api_key: "key", model: "jev-latest", timeout_seconds: 1,
        min_confidence: 0.5, secondary_probability: 0.25, http: JevResolverSpecSupport::TimeoutHttp.new
      )

      expect { resolve(jev) }.to raise_error(Llm::Client::Unavailable, "JEV request failed")
    end

    it "rejects malformed bodies and missing or mistyped answers while keeping the raw body" do
      malformed = JevResolverSpecSupport::Response.new("200", "not json", {})
      expect { resolve(resolver(malformed)) }
        .to raise_error(Llm::Client::InvalidResponse) { |error| expect(error.raw_response).to eq("not json") }

      missing = answers.except("service")
      expect { resolve(resolver(json_response(missing))) }.to raise_error(Llm::Client::InvalidResponse)

      mistyped = answers(service: {"type" => "choice", "choice" => electrician.slug})
      expect { resolve(resolver(json_response(mistyped))) }.to raise_error(Llm::Client::InvalidResponse)
    end
  end

  describe "JEV's 255-option limit per choice question" do
    let(:city_struct) { SupportedSearchLocations::Location }

    def location(code:, city:, state: "SP")
      city_struct.new(
        city_code: code, state_code: state, city:,
        state_slug: state.downcase, city_slug: city.parameterize
      )
    end

    def stub_supported_cities(extra)
      fillers = Array.new(300) { |index| location(code: format("90%05d", index), city: "Cidade Filler #{index}") }
      joinville = location(code: joinville_city.code, city: "Joinville", state: "SC")
      allow(SupportedSearchLocations).to receive(:new)
        .and_return(instance_double(SupportedSearchLocations, all: [joinville, *extra, *fillers]))
    end

    def sent_questions
      JSON.parse(@http.connection.requests.first.body).fetch("questions")
    end

    it "offers only the default city, the cities named in the text and outra_cidade" do
      sao_paulo = location(code: "3550308", city: "São Paulo")
      stub_supported_cities([sao_paulo, location(code: "3304557", city: "Rio de Janeiro", state: "RJ")])

      resolve(resolver(json_response(answers)), "Preciso de um pintor em Sao Paulo")

      expect(sent_questions.dig("city", "criteria").keys)
        .to eq([joinville_city.code, "3550308", "outra_cidade"])
    end

    it "offers only the default city and outra_cidade when the text names no supported city" do
      stub_supported_cities([])

      resolve(resolver(json_response(answers)), "Preciso de um pintor")

      expect(sent_questions.dig("city", "criteria").keys).to eq([joinville_city.code, "outra_cidade"])
    end

    it "prefers the longest city name over a shorter one it contains" do
      stub_supported_cities([
        location(code: "3304557", city: "Rio de Janeiro", state: "RJ"),
        location(code: "1200401", city: "Rio", state: "AC")
      ])

      resolve(resolver(json_response(answers)), "pintor no rio de janeiro")

      expect(sent_questions.dig("city", "criteria").keys)
        .to eq([joinville_city.code, "3304557", "outra_cidade"])
    end

    it "caps the number of candidate cities" do
      homonyms = Array.new(40) { |index| location(code: format("80%05d", index), city: "Santa Luzia", state: "XX") }
      stub_supported_cities(homonyms)

      resolve(resolver(json_response(answers)), "pintor em Santa Luzia")

      expect(sent_questions.dig("city", "criteria").size)
        .to eq(described_class::MAXIMUM_CITY_CANDIDATES + 2)
    end

    describe "neighborhoods" do
      let(:big_list) do
        Array.new(300) { |index| Struct.new(:code, :name).new(format("77%05d", index), "Bairro Filler #{index}") }
      end

      it "sends only the neighborhoods named in the text when the list is too long" do
        stub_supported_cities([])
        target = Struct.new(:code, :name).new("7799999", "Savassi")

        resolve(
          resolver(json_response(answers(neighborhood: choice("nenhum", 0.9, "nenhum" => 0.9, "7799999" => 0.1)))),
          "pintor na Savassi", neighborhoods: [*big_list, target]
        )

        expect(sent_questions.dig("neighborhood", "criteria").keys).to eq(["7799999", "nenhum"])
      end

      it "skips the neighborhood question when the list is too long and none is named" do
        stub_supported_cities([])

        resolve(resolver(json_response(answers)), "pintor em Joinville", neighborhoods: big_list)

        expect(sent_questions).not_to have_key("neighborhood")
      end

      it "keeps sending the whole list when it fits" do
        resolve(resolver(json_response(answers)), "pintor", neighborhoods: [america])

        expect(sent_questions.dig("neighborhood", "criteria").keys).to eq([america.code, "nenhum"])
      end
    end

    it "keeps the prompt digest independent of the expression and sensitive to the city list" do
      stub_supported_cities([])
      jev = resolver(json_response(answers))
      first = jev.prompt_digest(services:, neighborhoods:, default_location:)
      stub_supported_cities([location(code: "3550308", city: "São Paulo")])
      changed = resolver(json_response(answers)).prompt_digest(services:, neighborhoods:, default_location:)

      expect(changed).not_to eq(first)
      expect(jev.prompt_digest(services:, neighborhoods:, default_location:)).to eq(first)
    end
  end
end
