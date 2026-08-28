# frozen_string_literal: true

require "dbf"
require "json"
require "net/http"
require "stringio"
require "uri"
require "zip"

module Ibge
  class LocationSource
    ResourceNotFound = Class.new(StandardError)
    LOCALITIES_BASE_URL = "https://servicodados.ibge.gov.br/api/v1/localidades"
    NEIGHBORHOOD_BASE_URL = "https://geoftp.ibge.gov.br/organizacao_do_territorio/" \
      "malhas_territoriais/malhas_de_setores_censitarios__divisoes_intramunicipais/" \
      "censo_2022/bairros/shp/UF"
    MAXIMUM_DBF_BYTES = 100.megabytes
    Payload = Data.define(:states, :cities, :neighborhoods)

    attr_reader :missing_neighborhood_archives

    def initialize(state_abbreviations: nil, city_codes: nil, logger: Rails.logger)
      @state_abbreviations = normalize_filter(state_abbreviations, pattern: /\A[A-Z]{2}\z/)
      @city_codes = normalize_filter(city_codes, pattern: /\A\d{7}\z/)
      @logger = logger
      @missing_neighborhood_archives = []
    end

    def fetch
      states = fetch_states
      states = filter_states(states)
      cities = states.flat_map { |state| fetch_cities(state) }
      cities.select! { |city| city_codes.include?(city.fetch(:code)) } if city_codes.any?
      selected_city_codes = cities.pluck(:code).to_set
      neighborhoods = states.flat_map do |state|
        fetch_neighborhoods(state.fetch(:abbreviation), selected_city_codes)
      end

      Payload.new(states:, cities:, neighborhoods:)
    end

    private

    attr_reader :state_abbreviations, :city_codes, :logger

    def fetch_states
      get_json("#{LOCALITIES_BASE_URL}/estados?orderBy=nome").map do |row|
        {code: row.fetch("id").to_s, abbreviation: row.fetch("sigla"), name: row.fetch("nome")}
      end
    end

    def filter_states(states)
      requested = state_abbreviations.to_set
      requested.merge(city_codes.map { |code| code.first(2) })
      return states if requested.empty?

      selected = states.select do |state|
        requested.include?(state.fetch(:abbreviation)) || requested.include?(state.fetch(:code))
      end
      found = selected.flat_map { |state| [state.fetch(:abbreviation), state.fetch(:code)] }.to_set
      missing = requested.reject { |value| found.include?(value) }
      raise ArgumentError, "UFs desconhecidas: #{missing.to_a.sort.join(", ")}." if missing.any?

      selected
    end

    def fetch_cities(state)
      abbreviation = state.fetch(:abbreviation)
      get_json("#{LOCALITIES_BASE_URL}/estados/#{abbreviation}/municipios?orderBy=nome").map do |row|
        name = row.fetch("nome")
        {
          code: row.fetch("id").to_s,
          state_code: state.fetch(:code),
          name:,
          slug: name.parameterize
        }
      end
    end

    def fetch_neighborhoods(abbreviation, selected_city_codes)
      archive = get("#{NEIGHBORHOOD_BASE_URL}/#{abbreviation}_bairros_CD2022.zip")
      neighborhoods = nil
      Zip::File.open_buffer(StringIO.new(archive)) do |zip|
        entry = zip.entries.find { |candidate| candidate.file? && candidate.name.downcase.end_with?(".dbf") }
        raise ArgumentError, "Arquivo DBF ausente no ZIP de #{abbreviation}." unless entry
        raise ArgumentError, "Arquivo DBF de #{abbreviation} excede o limite permitido." if entry.size > MAXIMUM_DBF_BYTES

        table = DBF::Table.new(StringIO.new(entry.get_input_stream.read))
        neighborhoods = table.filter_map do |record|
          city_code = record["CD_MUN"].to_s.strip
          next unless selected_city_codes.include?(city_code)

          {
            code: record["CD_BAIRRO"].to_s.strip,
            city_code:,
            name: record["NM_BAIRRO"].to_s
          }
        end
      end
      neighborhoods
    rescue ResourceNotFound
      missing_neighborhood_archives << abbreviation
      logger.warn("O IBGE não publicou arquivo de bairros para #{abbreviation}; cidades importadas sem bairros.")
      []
    end

    def get_json(url)
      JSON.parse(get(url))
    rescue JSON::ParserError => error
      raise ArgumentError, "Resposta JSON inválida do IBGE: #{error.message}"
    end

    def get(url, redirects: 3)
      uri = URI.parse(url)
      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: 15,
        read_timeout: 120
      ) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "Berufe IBGE location importer"
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        raise ArgumentError, "Redirecionamentos demais ao consultar o IBGE." if redirects.zero?

        location = URI.join(uri, response["location"].to_s)
        raise ArgumentError, "Redirecionamento inseguro ao consultar o IBGE." unless location.scheme == "https"

        get(location.to_s, redirects: redirects - 1)
      when Net::HTTPNotFound
        raise ResourceNotFound, "Recurso ausente no IBGE: #{uri}."
      else
        raise ArgumentError, "O IBGE respondeu HTTP #{response.code} para #{uri.host}."
      end
    end

    def normalize_filter(values, pattern:)
      Array(values).flat_map { |value| value.to_s.split(",") }
        .map(&:strip)
        .reject(&:blank?)
        .map(&:upcase)
        .uniq
        .tap do |normalized|
          invalid = normalized.reject { |value| value.match?(pattern) }
          raise ArgumentError, "Filtros IBGE inválidos: #{invalid.join(", ")}." if invalid.any?
        end
    end
  end
end
