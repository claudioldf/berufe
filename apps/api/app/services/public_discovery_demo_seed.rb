# frozen_string_literal: true

require "json"

class PublicDiscoveryDemoSeed
  ALLOWED_ENVIRONMENTS = %w[local test].freeze
  CONTENT_TYPE = "image/jpeg"
  DEMO_CITY_CODES = %w[4209102 4202404 4106902 4202008].freeze
  PROFESSIONALS_PER_CATEGORY_AND_CITY = 2

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
    generated = seed_category_city_matrix(initiator: profiles.values.first)
    profiles.values + generated
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
      record.phone_verified_at = Time.current
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
    coverage = attributes.fetch("coverage")
    city_code = coverage.dig("city", "code")
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
    neighborhood_codes = coverage.fetch("neighborhoods").pluck("code")

    ProfessionalProfileSupplyUpdater.new.call(
      profile:,
      services: selected_services,
      coverage: {
        city_code:,
        whole_city: coverage.fetch("wholeCity"),
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

        ProfessionalRelationship.find_or_create_by!(
          initiator_professional: initiator,
          recipient_professional: recipient,
          relationship_type: relationship.fetch("type")
        ) do |candidate|
          candidate.status = "accepted"
          candidate.context_note = relationship.fetch("note")
          candidate.responded_at = Time.current
        end
      end
    end
  end

  def seed_category_city_matrix(initiator:)
    generated = []
    cities = City.where(code: DEMO_CITY_CODES).includes(:state).index_by(&:code)
    raise ActiveRecord::RecordNotFound, "demo cities" unless cities.length == DEMO_CITY_CODES.length

    ServiceCategory.active.ordered.each_with_index do |category, category_index|
      services = category.services.publicly_active.ordered.to_a
      raise ActiveRecord::RecordNotFound, "demo category services" if services.empty?

      DEMO_CITY_CODES.each_with_index do |city_code, city_index|
        city = cities.fetch(city_code)
        count = primary_professional_count(category:, city:)
        (PROFESSIONALS_PER_CATEGORY_AND_CITY - count).times do |offset|
          sequence = count + offset + 1
          service = services[(sequence - 1) % services.length]
          phone = generated_phone(city:, city_index:, category_index:, sequence:)
          existing = UserAccount.find_by(phone_e164: phone)&.professional_profile
          if existing
            generated << existing
            next
          end

          relationship = ProfessionalRelationshipRequester.new.call(
            initiator:,
            target: {
              type: "phone",
              name: "Profissional #{category.name} #{city.name} #{sequence}",
              phone:,
              service_ids: [service.id],
              coverage: {city_code:, whole_city: true, neighborhood_codes: []},
              contact_publication_attested: true
            },
            relationship_type: "worked_together",
            context_note: "Perfil sintético para desenvolvimento local."
          )
          profile = relationship.recipient_professional
          ModerationDecision.new(context: admin_context).call(
            target_type: "profile_revision",
            target_id: profile.published_revision_id,
            action: "approved"
          )
          generated << profile.reload
        end
      end
    end
    generated
  end

  def primary_professional_count(category:, city:)
    ProfessionalProfile
      .publicly_searchable
      .joins(published_revision: {professional_profile_services: :service})
      .where(professional_profile_revisions: {coverage_city_code: city.code})
      .where(professional_profile_services: {is_primary: true})
      .where(services: {category_id: category.id})
      .distinct
      .count
  end

  def generated_phone(city:, city_index:, category_index:, sequence:)
    area_code = (city.state.abbreviation == "PR") ? "41" : "47"
    subscriber = format("99%d%d%05d", city_index, category_index, sequence)
    "+55#{area_code}#{subscriber}"
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
