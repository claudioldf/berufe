# frozen_string_literal: true

require "json"

class PublicDiscoveryDemoSeed
  ALLOWED_ENVIRONMENTS = %w[local test].freeze
  CONTENT_TYPE = "image/jpeg"

  def self.default_data_path
    configured_path = ENV["PROFESSIONAL_DEMO_SEED_PATH"].presence
    return Pathname(configured_path) if configured_path

    [Pathname("/catalog-data/professionals.json"), Rails.root.join("../web/data/professionals.json")]
      .find(&:file?) || raise(Errno::ENOENT, "apps/web/data/professionals.json")
  end

  def self.default_image_root
    configured_path = ENV["PROFESSIONAL_DEMO_IMAGE_ROOT"].presence
    return Pathname(configured_path) if configured_path

    [Pathname("/demo-images"), Rails.root.join("../web/public/images")]
      .find(&:directory?) || raise(Errno::ENOENT, "apps/web/public/images")
  end

  def initialize(
    data_path: nil,
    image_root: nil,
    environment_name: Rails.configuration.x.berufe.environment.name,
    logger: Rails.logger
  )
    @data_path = data_path && Pathname(data_path)
    @image_root = image_root && Pathname(image_root)
    @environment_name = environment_name
    @logger = logger
  end

  def call
    unless environment_name.in?(ALLOWED_ENVIRONMENTS)
      logger.warn("Public discovery demo seed skipped outside local/test.")
      return
    end

    professionals = JSON.parse(resolved_data_path.read)
    profiles = professionals.to_h do |attributes|
      [attributes.fetch("slug"), seed_professional(attributes)]
    end
    seed_relationships(professionals, profiles)
    profiles.values
  end

  private

  attr_reader :data_path, :image_root, :environment_name, :logger

  def resolved_data_path
    data_path || self.class.default_data_path
  end

  def resolved_image_root
    image_root || self.class.default_image_root
  end

  def seed_professional(attributes)
    existing = ProfessionalProfile.find_by(public_slug: attributes.fetch("slug"))
    return existing if existing

    account = UserAccount.find_or_create_by!(phone_e164: "+#{attributes.fetch("whatsapp")}") do |record|
      record.role = "professional"
      record.status = "active"
    end
    profile = ProfessionalRegistration.new.call(
      user_account: account,
      display_name: attributes.fetch("name"),
      accepted: true
    )
    profile.update!(public_slug: attributes.fetch("slug"))
    update_identity(profile, attributes)
    update_supply(profile, attributes)
    photo = attach_profile_photo(profile, attributes.fetch("avatar"))
    portfolio = attach_portfolio(profile, attributes.fetch("portfolio"))
    verification = attach_identity_verification(profile, attributes.fetch("avatar"))
    ProfessionalProfileSubmitter.new.call(profile:)
    approve_professional(profile:, photo:, portfolio:, verification:)
    profile.reload
    profile.published_revision.update_columns(
      submitted_at: Time.zone.parse("#{attributes.fetch("updatedAt")} 12:00:00"),
      reviewed_at: Time.zone.parse("#{attributes.fetch("updatedAt")} 12:00:00")
    )
    profile.reload
  end

  def update_identity(profile, attributes)
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: attributes.fetch("name"),
        birthdate: attributes.fetch("birthdate", "1990-01-01"),
        headline: attributes.fetch("headline"),
        bio: attributes.fetch("bio"),
        years_experience: attributes["yearsExperience"],
        whatsapp: attributes.fetch("whatsapp"),
        instagram: attributes["instagram"],
        youtube: attributes["youtube"]
      }
    )
  end

  def update_supply(profile, attributes)
    primary_slug = attributes.fetch("primaryServiceSlug")
    notes = attributes.fetch("serviceNotes")
    selected_services = attributes.fetch("services").each_with_index.map do |name, index|
      service = Service.find_by!(name:)
      {
        service_id: service.id,
        is_primary: service.slug == primary_slug,
        note: notes[index]
      }
    end
    neighborhood_codes = if attributes.fetch("allJoinville")
      []
    else
      neighborhood_names = attributes.fetch("neighborhoods")
      codes = Neighborhood.where(name: neighborhood_names).pluck(:code)
      raise ActiveRecord::RecordNotFound, "demo neighborhoods" unless codes.length == neighborhood_names.length

      codes
    end

    ProfessionalProfileSupplyUpdater.new.call(
      profile:,
      services: selected_services,
      coverage: {
        all_joinville: attributes.fetch("allJoinville"),
        neighborhood_codes:
      }
    )
  end

  def attach_profile_photo(profile, source_path)
    upload = process_upload(profile:, purpose: "profile_photo", source_path:)
    ProfessionalProfilePhotoAttacher.new.call(profile:, media_upload_id: upload.id)
  end

  def attach_portfolio(profile, portfolio)
    portfolio.map do |attributes|
      upload = process_upload(
        profile:,
        purpose: "portfolio_image",
        source_path: attributes.fetch("image")
      )
      PortfolioItemCreator.new.call(
        profile:,
        attributes: {
          media_upload_id: upload.id,
          service_id: Service.find_by!(name: attributes.fetch("service")).id,
          title: attributes.fetch("title"),
          description: attributes["description"]
        }
      )
    end
  end

  def attach_identity_verification(profile, source_path)
    upload = process_upload(profile:, purpose: "verification_identity", source_path:)
    VerificationRequestCreator.new.call(
      profile:,
      media_upload_id: upload.id,
      verification_type: "identity"
    )
  end

  def process_upload(profile:, purpose:, source_path:)
    body = image_body(source_path)
    upload, = MediaUploadAuthorizer.new.call(
      profile:,
      purpose:,
      content_type: CONTENT_TYPE,
      byte_size: body.bytesize
    )
    MediaUploadReceiver.new.call(upload:, body:, content_type: CONTENT_TYPE)
    MediaUploadProcessor.new.call(upload:)
    upload.reload
    raise "demo media processing failed: #{upload.failure_code}" unless upload.processed?

    upload
  end

  def image_body(source_path)
    filename = File.basename(source_path)
    raise ArgumentError, "invalid demo image path" unless source_path == "/images/#{filename}"

    resolved_image_root.join(filename).binread
  end

  def approve_professional(profile:, photo:, portfolio:, verification:)
    decision = ModerationDecision.new(context: admin_context)
    decision.call(target_type: "profile_revision", target_id: profile.working_revision_id, action: "approved")
    decision.call(target_type: "profile_photo", target_id: photo.id, action: "approved")
    portfolio.each do |item|
      decision.call(target_type: "portfolio_item", target_id: item.id, action: "approved")
    end
    decision.call(
      target_type: "verification_request",
      target_id: verification.id,
      action: "approved",
      identity_match_confirmed: true
    )
  end

  def seed_relationships(professionals, profiles)
    seeded_pairs = Set.new
    professionals.each do |attributes|
      initiator = profiles.fetch(attributes.fetch("slug"))
      attributes.fetch("relationships").each do |relationship|
        recipient = profiles.fetch(relationship.fetch("professionalSlug"))
        pair = [initiator.id, recipient.id].sort.push(relationship.fetch("type"))
        next unless seeded_pairs.add?(pair)

        record = ProfessionalRelationship.find_or_create_by!(
          initiator_professional: initiator,
          recipient_professional: recipient,
          relationship_type: relationship.fetch("type")
        ) do |candidate|
          candidate.status = "accepted"
          candidate.context_note = relationship.fetch("note")
          candidate.responded_at = Time.current
        end
        next unless record.moderation_status == "pending_review"

        ModerationDecision.new(context: admin_context).call(
          target_type: "professional_relationship",
          target_id: record.id,
          action: "approved"
        )
      end
    end
  end

  def admin_context
    @admin_context ||= AdminActionContext.new(
      admin_user_id: admin_account.id,
      request_id: "public-discovery-demo-seed"
    )
  end

  def admin_account
    @admin_account ||= UserAccount.find_by!(role: "admin", status: "active")
  end
end
