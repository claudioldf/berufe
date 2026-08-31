# frozen_string_literal: true

namespace :external_professionals do
  desc "Importa profissionais externos a partir de CSV_PATH. Use DRY_RUN=true para simular sem gravar."
  task import: :environment do
    csv_path = ENV.fetch("CSV_PATH")
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV["DRY_RUN"])

    puts "Modo simulação: nenhuma gravação será feita." if dry_run
    result = ExternalProfessionalImporter.new.call(csv_path:, dry_run:)

    puts
    puts result.summary

    if result.skipped.any?
      puts
      puts "Ignorados:"
      result.skipped.each { |row| puts "  - #{row.context}: #{row.reason}" }
    end

    if result.failed.any?
      puts
      puts "Falharam:"
      result.failed.each { |row| puts "  - #{row.context}: #{row.reason}" }
    end
  end
end
