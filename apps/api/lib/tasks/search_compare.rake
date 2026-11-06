# frozen_string_literal: true

namespace :search do
  desc "Compare the llm and jev search resolvers on an expression, or on a file with one expression per line"
  task :compare, [:input] => :environment do |_task, args|
    input = args[:input].to_s.strip
    abort "Uso: bin/rails \"search:compare[preciso de um eletricista]\" (ou o caminho de um arquivo)" if input.empty?

    expressions = File.file?(input) ? File.readlines(input, chomp: true).map(&:strip).reject(&:empty?) : [input]
    comparison = SearchResolverComparison.new

    expressions.each do |expression|
      puts "Expressão: #{expression}"
      comparison.call(expression:).each do |result|
        label = result.adapter ? "#{result.name} (#{result.adapter}/#{result.model})" : result.name
        puts "  #{label}  #{result.latency_ms} ms"
        if result.error
          puts "    erro: #{result.error}"
          next
        end

        puts "    serviços:  #{result.services.presence&.join(", ") || "—"}"
        puts "    locais:    #{result.locations.join(" | ")}"
        puts "    pedido:    #{result.normalized_request || "—"}"
        puts "    sinais:    #{result.signals}" if result.signals
      end
      puts
    end
  end
end
