# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalProfileFallbackCopy do
  let(:service_selection_class) do
    Data.define(:id, :service, :primary) do
      def is_primary?
        primary
      end
    end
  end
  let(:service_value_class) { Data.define(:name) }
  let(:city_value_class) { Data.define(:name) }
  let(:neighborhood_value_class) { Data.define(:code, :name) }
  let(:service_area_value_class) { Data.define(:neighborhood) }
  let(:portfolio_value_class) { Data.define(:id, :title, :submitted_at, :deleted_at) }
  let(:revision_value_class) do
    Data.define(
      :headline,
      :bio,
      :years_experience,
      :coverage_city,
      :whole_city,
      :professional_profile_services,
      :professional_profile_service_areas
    ) do
      def covers_whole_city?
        whole_city
      end
    end
  end
  let(:profile_value_class) do
    Data.define(:published_revision, :portfolio_items, :external) do
      def external_presentation?
        external
      end
    end
  end

  it "builds fallback copy from services, specific coverage, experience, and active portfolio work" do
    revision = revision_with(
      years_experience: 11,
      coverage_city: city_value_class.new(name: "Joinville"),
      whole_city: false,
      professional_profile_services: [
        selection(2, "Marido de aluguel", primary: false),
        selection(1, "Eletricista", primary: true)
      ],
      professional_profile_service_areas: [
        area("4209102002", "Centro"),
        area("4209102001", "América")
      ]
    )
    profile = profile_value_class.new(
      published_revision: revision,
      external: false,
      portfolio_items: [
        portfolio(2, "Troca de tomadas", 1.day.ago),
        portfolio(1, "Quadro organizado", 2.days.ago),
        portfolio(3, "Trabalho removido", Time.current, deleted_at: Time.current)
      ]
    )

    result = described_class.call(profile:)

    expect(result.headline).to eq("Eletricista em Joinville com 11 anos de experiência")
    expect(result.bio).to eq(
      "Ofereço serviços como eletricista e marido de aluguel em Joinville, " \
      "com atendimento nos bairros América e Centro. Tenho 11 anos de experiência na área. " \
      "No meu portfólio, você pode conhecer trabalhos como “Troca de tomadas” e “Quadro organizado”."
    )
    expect(result.bio).not_to include("Trabalho removido")
  end

  it "preserves each professional-authored field independently" do
    authored_headline = revision_with(headline: "Atendimento cuidadoso.")
    authored_bio = revision_with(bio: "Texto escrito pela profissional.")

    headline_result = described_class.call(profile: profile_with(authored_headline))
    bio_result = described_class.call(profile: profile_with(authored_bio))

    expect(headline_result).to have_attributes(
      headline: "Atendimento cuidadoso.",
      bio: "Aqui você encontra mais informações sobre o meu trabalho e pode falar comigo para saber mais."
    )
    expect(bio_result).to have_attributes(
      headline: "Perfil profissional",
      bio: "Texto escrito pela profissional."
    )
  end

  it "omits experience below one year and portfolio copy for external profiles" do
    revision = revision_with(
      years_experience: 0,
      coverage_city: city_value_class.new(name: "Joinville"),
      whole_city: true,
      professional_profile_services: [selection(1, "Pintor", primary: true)]
    )
    profile = profile_value_class.new(
      published_revision: revision,
      external: true,
      portfolio_items: [portfolio(1, "Pintura externa", Time.current)]
    )

    result = described_class.call(profile:)

    expect(result.headline).to eq("Pintor em Joinville")
    expect(result.bio).to eq("Oferece serviços como pintor em toda a cidade de Joinville.")
  end

  private

  def revision_with(**attributes)
    revision_value_class.new(
      headline: nil,
      bio: nil,
      years_experience: nil,
      coverage_city: nil,
      whole_city: false,
      professional_profile_services: [],
      professional_profile_service_areas: [],
      **attributes
    )
  end

  def profile_with(revision)
    profile_value_class.new(published_revision: revision, portfolio_items: [], external: false)
  end

  def selection(id, name, primary:)
    service_selection_class.new(id:, service: service_value_class.new(name:), primary:)
  end

  def area(code, name)
    service_area_value_class.new(neighborhood: neighborhood_value_class.new(code:, name:))
  end

  def portfolio(id, title, submitted_at, deleted_at: nil)
    portfolio_value_class.new(id:, title:, submitted_at:, deleted_at:)
  end
end
