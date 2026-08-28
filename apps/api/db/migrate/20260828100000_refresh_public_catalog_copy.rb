# frozen_string_literal: true

class RefreshPublicCatalogCopy < ActiveRecord::Migration[8.1]
  COPY_CHANGES = {
    "eletricista" => {
      description: [
        "Instalações, reparos, quadros elétricos e iluminação residencial.",
        "Instalações, reparos, quadros elétricos e iluminação."
      ]
    },
    "encanador" => {
      description: [
        "Reparos hidráulicos, instalações e solução de vazamentos.",
        "Instalações e reparos hidráulicos, incluindo vazamentos."
      ]
    },
    "marceneiro" => {
      description: [
        "Móveis sob medida, ajustes e reparos de madeira.",
        "Móveis sob medida, ajustes e reparos em madeira."
      ]
    },
    "montador-de-moveis" => {
      description: [
        "Montagem, desmontagem e regulagem de móveis residenciais.",
        "Montagem, desmontagem e regulagem de móveis."
      ]
    },
    "arquiteto" => {
      description: [
        "Projetos de reforma, interiores e acompanhamento de obra.",
        "Projetos arquitetônicos e de interiores, com acompanhamento de obra."
      ]
    },
    "designer-de-interiores" => {
      description: [
        "Planejamento funcional e estético de ambientes residenciais.",
        "Planejamento funcional e estético de ambientes."
      ]
    },
    "marido-de-aluguel" => {
      name: ["Marido de aluguel", "Pequenos reparos"],
      description: [
        "Pequenas instalações, ajustes e reparos do dia a dia.",
        "Instalações, ajustes e consertos do dia a dia."
      ]
    },
    "telhados-e-calhas" => {
      description: [
        "Instalação, manutenção e reparo de telhados, calhas e rufos residenciais.",
        "Instalação e reparo de telhados, calhas e rufos."
      ]
    },
    "ar-condicionado" => {
      description: [
        "Instalação, limpeza e manutenção de ar-condicionado residencial.",
        "Instalação, limpeza e manutenção de ar-condicionado."
      ]
    },
    "serralheiro" => {
      description: [
        "Portões, grades, corrimãos e estruturas metálicas residenciais.",
        "Portões, grades, corrimãos e estruturas metálicas."
      ]
    },
    "vidraceiro" => {
      description: [
        "Instalação e substituição de vidros, espelhos e boxes residenciais.",
        "Instalação e troca de vidros, espelhos e boxes."
      ]
    },
    "impermeabilizacao" => {
      description: [
        "Tratamento de infiltrações e impermeabilização de áreas residenciais.",
        "Tratamento de infiltrações e impermeabilização de áreas da casa."
      ]
    },
    "limpeza-residencial" => {
      name: ["Limpeza Residencial", "Limpeza residencial"],
      description: [
        "Limpeza completa e recorrente de casas e apartamentos.",
        "Limpeza completa ou recorrente de casas e apartamentos."
      ]
    },
    "chaveiro" => {
      description: [
        "Abertura, troca e instalação de fechaduras residenciais.",
        "Abertura de portas, troca e instalação de fechaduras."
      ]
    },
    "desentupidor" => {
      name: ["Desentupidor", "Desentupimento"]
    },
    "jardinagem" => {
      description: [
        "Manutenção, poda e cuidados com jardins residenciais.",
        "Manutenção, poda e cuidados com jardins."
      ]
    },
    "petsitter" => {
      name: ["Petsitter", "Cuidados para pets"],
      description: [
        "Cuidados, visitas e companhia para pets.",
        "Visitas, companhia e cuidados para pets em casa."
      ]
    },
    "freelancer" => {
      description: [
        "Serviços profissionais independentes e sob demanda.",
        "Serviços profissionais para demandas pontuais."
      ]
    }
  }.freeze

  def up
    apply_copy(direction: :forward)
  end

  def down
    apply_copy(direction: :reverse)
  end

  private

  def apply_copy(direction:)
    COPY_CHANGES.each do |slug, fields|
      fields.each do |field, values|
        from, to = (direction == :forward) ? values : values.reverse
        update_value(slug:, field:, from:, to:)
      end
    end
  end

  def update_value(slug:, field:, from:, to:)
    quoted_field = connection.quote_column_name(field)

    execute <<~SQL.squish
      UPDATE services
      SET #{quoted_field} = #{connection.quote(to)}, updated_at = CURRENT_TIMESTAMP
      WHERE slug = #{connection.quote(slug)}
        AND #{quoted_field} = #{connection.quote(from)}
    SQL
  end
end
