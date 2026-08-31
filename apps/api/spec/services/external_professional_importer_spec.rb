# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe ExternalProfessionalImporter do
  let(:pedreiro) { create_catalog_service(slug: "pedreiro") }
  let(:pintor) { create_catalog_service(slug: "pintor") }

  def create_catalog_service(slug:)
    category = ServiceCategory.find_or_create_by!(slug: "importer-spec-category") do |record|
      record.name = "Categoria de teste"
      record.icon = "i-lucide-wrench"
      record.is_active = true
      record.sort_order = 0
    end
    Service.create!(
      category:,
      name: slug.titleize,
      slug:,
      icon: "i-lucide-wrench",
      description: "Serviço de teste.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  def csv_with(rows)
    header = %w[display_name whatsapp_e164 email instagram_url headline description services_mapped services_raw
      city city_code source_url source_csv_lines needs_review]
    file = Tempfile.new(["leads", ".csv"])
    CSV.open(file.path, "w") do |csv|
      csv << header
      rows.each { |row| csv << header.map { |column| row[column] } }
    end
    file
  end

  it "creates a draft external profile with the mapped services, primary first, and city coverage" do
    pedreiro
    pintor
    file = csv_with([{
      "display_name" => "  Adriano  Silva ",
      "whatsapp_e164" => "+5547988887777",
      "headline" => "Marido de aluguel",
      "description" => "Faço reparos em geral.",
      "instagram_url" => "https://www.instagram.com/adrianosilva/",
      "services_mapped" => "pedreiro;pintor",
      "city_code" => "4209102"
    }])

    result = described_class.new.call(csv_path: file.path)

    expect(result.imported.size).to eq(1)
    expect(result.skipped).to be_empty
    expect(result.failed).to be_empty

    account = UserAccount.find_by(phone_e164: "+5547988887777")
    profile = account.professional_profile
    expect(profile).to have_attributes(creation_source: "external", profile_status: "draft")

    revision = profile.working_revision
    expect(revision).to have_attributes(
      profile_type: "external",
      display_name: "Adriano Silva",
      headline: "Marido de aluguel",
      bio: "Faço reparos em geral.",
      whatsapp_e164: "+5547988887777",
      instagram_url: "https://www.instagram.com/adrianosilva/",
      coverage_city_code: "4209102",
      covers_whole_city: true
    )
    selections = revision.professional_profile_services.includes(:service).index_by { |s| s.service.slug }
    expect(selections["pedreiro"]).to have_attributes(is_primary: true)
    expect(selections["pintor"]).to have_attributes(is_primary: false)
  end

  it "leaves coverage unset and creates no service selections when the row has neither" do
    file = csv_with([{
      "display_name" => "Sem Cidade",
      "whatsapp_e164" => "+5547988887778",
      "services_mapped" => "",
      "city_code" => ""
    }])

    result = described_class.new.call(csv_path: file.path)

    expect(result.imported.size).to eq(1)
    revision = UserAccount.find_by(phone_e164: "+5547988887778").professional_profile.working_revision
    expect(revision).to have_attributes(coverage_city_code: nil, covers_whole_city: false)
    expect(revision.professional_profile_services).to be_empty
  end

  it "skips a row whose phone already has an account, without touching it" do
    existing = UserAccount.create!(phone_e164: "+5547988887779", role: "professional", status: "active")
    file = csv_with([{"display_name" => "Já Existe", "whatsapp_e164" => "+5547988887779"}])

    result = described_class.new.call(csv_path: file.path)

    expect(result.imported).to be_empty
    expect(result.skipped.size).to eq(1)
    expect(existing.reload.professional_profile).to be_nil
  end

  it "fails a row with an unrecognizable phone number without aborting the batch" do
    file = csv_with([
      {"display_name" => "Telefone Ruim", "whatsapp_e164" => "123"},
      {"display_name" => "Telefone Bom", "whatsapp_e164" => "+5547988887780"}
    ])

    result = described_class.new.call(csv_path: file.path)

    expect(result.failed.size).to eq(1)
    expect(result.failed.first).to have_attributes(context: "Telefone Ruim (123)", reason: include("123"))
    expect(result.imported.size).to eq(1)
    expect(UserAccount.exists?(phone_e164: "+5547988887780")).to be(true)
  end

  it "does not persist anything in dry-run mode but reports the row as importable" do
    file = csv_with([{"display_name" => "Simulado", "whatsapp_e164" => "+5547988887781"}])

    result = described_class.new.call(csv_path: file.path, dry_run: true)

    expect(result.imported.size).to eq(1)
    expect(result.imported.first.profile_id).to be_nil
    expect(UserAccount.exists?(phone_e164: "+5547988887781")).to be(false)
  end

  it "ignores unknown service slugs instead of failing the row" do
    pedreiro
    file = csv_with([{
      "display_name" => "Slug Desconhecido",
      "whatsapp_e164" => "+5547988887782",
      "services_mapped" => "servico-inexistente;pedreiro"
    }])

    result = described_class.new.call(csv_path: file.path)

    expect(result.imported.size).to eq(1)
    revision = UserAccount.find_by(phone_e164: "+5547988887782").professional_profile.working_revision
    expect(revision.professional_profile_services.sole).to have_attributes(service: pedreiro, is_primary: true)
  end
end
