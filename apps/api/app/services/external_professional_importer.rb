# frozen_string_literal: true

require "csv"

# Bulk-imports professionals sourced from outside Berufe (e.g. scraped
# classifieds leads, normalized into a CSV with display_name/whatsapp_e164/
# headline/description/services_mapped/city_code columns) as draft,
# unpublished profiles with creation_source: "external".
#
# Deliberately does not verify the phone, register the account, or publish
# the profile: those steps require the professional to claim the account
# via OTP (ProfessionalRegistration), or an admin to review and publish
# through the normal moderation flow (see ProfessionalProfile#externally_eligible
# for what publication additionally requires). This importer only stages data.
#
# Safe to re-run: any phone number that already has a UserAccount (from a
# prior import run, a self-service signup, or anything else) is skipped
# untouched, never merged or overwritten.
class ExternalProfessionalImporter
  Outcome = Struct.new(:status, :context, :reason, :profile_id)
  Result = Struct.new(:imported, :skipped, :failed) do
    def summary
      "importados=#{imported.size} ignorados=#{skipped.size} falharam=#{failed.size}"
    end
  end

  def initialize(logger: Rails.logger)
    @logger = logger
  end

  def call(csv_path:, dry_run: false)
    imported = []
    skipped = []
    failed = []

    CSV.foreach(csv_path, headers: true) do |row|
      outcome = import_row(row, dry_run:)
      case outcome.status
      when :imported then imported << outcome
      when :skipped then skipped << outcome
      when :failed then failed << outcome
      end
    end

    Result.new(imported:, skipped:, failed:)
  end

  private

  attr_reader :logger

  def import_row(row, dry_run:)
    display_name = row["display_name"].to_s.squish
    context = "#{display_name} (#{row["whatsapp_e164"]})"

    return Outcome.new(status: :failed, context:, reason: "display_name ausente") if display_name.blank?

    phone_e164 = normalize_phone(row["whatsapp_e164"])
    return Outcome.new(status: :failed, context:, reason: "telefone inválido: #{row["whatsapp_e164"]}") unless phone_e164

    return Outcome.new(status: :skipped, context:, reason: "telefone já possui conta") if UserAccount.exists?(phone_e164:)

    create_professional!(row:, display_name:, phone_e164:, context:, dry_run:)
  rescue ActiveRecord::RecordInvalid => e
    Outcome.new(status: :failed, context:, reason: e.record.errors.full_messages.join("; "))
  end

  def create_professional!(row:, display_name:, phone_e164:, context:, dry_run:)
    profile_id = nil

    ActiveRecord::Base.transaction(requires_new: true) do
      account = UserAccount.create!(phone_e164:, role: "professional", status: "active")
      profile = build_profile!(account:, display_name:, phone_e164:, row:)
      profile_id = profile.id
      raise ActiveRecord::Rollback if dry_run
    end

    Outcome.new(status: :imported, context:, profile_id: dry_run ? nil : profile_id)
  end

  def build_profile!(account:, display_name:, phone_e164:, row:)
    headline = row["headline"].to_s.squish.presence
    bio = row["description"].to_s.squish.presence
    city_code = row["city_code"].to_s.strip.presence
    instagram_url = row["instagram_url"].to_s.strip.presence

    profile = account.build_professional_profile(
      creation_source: "external",
      display_name:,
      headline:,
      bio:,
      whatsapp_e164: phone_e164,
      instagram_url:
    )
    profile.save!

    # ProfessionalProfile#create_initial_revision! always stamps the first
    # revision as profile_type: "self_service" regardless of creation_source
    # (see app/models/professional_profile.rb). Repurpose it in place, the
    # same way spec/services/professional_registration_spec.rb builds its
    # external-profile fixture, rather than leaving it as an orphaned
    # placeholder and creating a second revision.
    revision = profile.working_revision
    revision.update!(
      profile_type: "external",
      coverage_city_code: city_code,
      covers_whole_city: city_code.present?,
      instagram_url:
    )

    attach_services!(revision:, row:)
    profile
  end

  def attach_services!(revision:, row:)
    slugs = row["services_mapped"].to_s.split(";").map(&:strip).reject(&:blank?).uniq
    return if slugs.empty?

    services_by_slug = Service.where(slug: slugs).index_by(&:slug)
    missing = slugs - services_by_slug.keys
    logger.warn("ExternalProfessionalImporter: unknown service slugs #{missing.join(", ")}") if missing.any?

    primary_assigned = false
    slugs.each do |slug|
      service = services_by_slug[slug]
      next unless service

      revision.professional_profile_services.create!(service_id: service.id, is_primary: !primary_assigned)
      primary_assigned = true
    end
  end

  def normalize_phone(raw)
    BrazilianPhoneNumber.normalize(raw)
  rescue BrazilianPhoneNumber::Invalid
    nil
  end
end
