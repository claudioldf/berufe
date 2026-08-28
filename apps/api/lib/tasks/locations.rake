# frozen_string_literal: true

namespace :locations do
  desc "Importa estados, municípios e bairros oficiais do IBGE"
  task import_ibge: :environment do
    source = Ibge::LocationSource.new(
      state_abbreviations: ENV["IBGE_UFS"],
      city_codes: ENV["IBGE_CITY_CODES"]
    )
    payload = source.fetch
    result = Ibge::LocationImporter.new.call(
      states: payload.states,
      cities: payload.cities,
      neighborhoods: payload.neighborhoods
    )

    puts "Importação do IBGE concluída: " \
      "#{result.states} estados, #{result.cities} cidades e " \
      "#{result.neighborhoods} bairros processados."
  end
end
