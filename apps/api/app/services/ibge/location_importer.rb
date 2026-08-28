# frozen_string_literal: true

module Ibge
  class LocationImporter
    Result = Data.define(:states, :cities, :neighborhoods)

    def call(states:, cities:, neighborhoods:)
      rows = normalize(states:, cities:, neighborhoods:)
      validate!(**rows)
      now = Time.current

      ActiveRecord::Base.transaction do
        State.upsert_all(with_timestamps(rows.fetch(:states), now), unique_by: :code)
        City.upsert_all(with_timestamps(rows.fetch(:cities), now), unique_by: :code)
        Neighborhood.upsert_all(with_timestamps(rows.fetch(:neighborhoods), now), unique_by: :code)
      end

      Result.new(
        states: rows.fetch(:states).length,
        cities: rows.fetch(:cities).length,
        neighborhoods: rows.fetch(:neighborhoods).length
      )
    end

    private

    def normalize(states:, cities:, neighborhoods:)
      {
        states: states.map do |row|
          {
            code: row.fetch(:code).to_s.strip,
            abbreviation: row.fetch(:abbreviation).to_s.strip.upcase,
            name: row.fetch(:name).to_s.squish
          }
        end,
        cities: cities.map do |row|
          name = row.fetch(:name).to_s.squish
          {
            code: row.fetch(:code).to_s.strip,
            state_code: row.fetch(:state_code).to_s.strip,
            name:,
            slug: row.fetch(:slug, name.parameterize).to_s.strip
          }
        end,
        neighborhoods: neighborhoods.map do |row|
          {
            code: row.fetch(:code).to_s.strip,
            city_code: row.fetch(:city_code).to_s.strip,
            name: row.fetch(:name).to_s.squish
          }
        end
      }
    end

    def validate!(states:, cities:, neighborhoods:)
      validate_collection!(states, type: "estado", code_pattern: /\A\d{2}\z/)
      validate_collection!(cities, type: "cidade", code_pattern: /\A\d{7}\z/)
      validate_collection!(neighborhoods, type: "bairro", code_pattern: /\A\d{10}\z/)

      state_codes = states.pluck(:code).to_set
      unknown_state = cities.find { |city| !state_codes.include?(city.fetch(:state_code)) }
      raise ArgumentError, "Cidade #{unknown_state.fetch(:code)} referencia um estado ausente." if unknown_state

      city_codes = cities.pluck(:code).to_set
      unknown_city = neighborhoods.find { |neighborhood| !city_codes.include?(neighborhood.fetch(:city_code)) }
      raise ArgumentError, "Bairro #{unknown_city.fetch(:code)} referencia uma cidade ausente." if unknown_city

      invalid_state = states.find { |state| !state.fetch(:abbreviation).match?(/\A[A-Z]{2}\z/) }
      raise ArgumentError, "Sigla de estado inválida para #{invalid_state.fetch(:code)}." if invalid_state

      invalid_slug = cities.find { |city| !city.fetch(:slug).match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/) }
      raise ArgumentError, "Slug de cidade inválido para #{invalid_slug.fetch(:code)}." if invalid_slug
    end

    def validate_collection!(rows, type:, code_pattern:)
      blank_name = rows.find { |row| row.fetch(:name).blank? }
      raise ArgumentError, "Nome de #{type} ausente." if blank_name

      invalid_code = rows.find { |row| !row.fetch(:code).match?(code_pattern) }
      raise ArgumentError, "Código de #{type} inválido: #{invalid_code.fetch(:code)}." if invalid_code

      duplicate_code = rows.group_by { |row| row.fetch(:code) }.find { |_code, grouped| grouped.many? }&.first
      raise ArgumentError, "Código de #{type} duplicado: #{duplicate_code}." if duplicate_code
    end

    def with_timestamps(rows, timestamp)
      rows.map { |row| row.merge(created_at: timestamp, updated_at: timestamp) }
    end
  end
end
