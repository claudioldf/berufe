# frozen_string_literal: true

class ProfessionalProfile < ApplicationRecord
  STATUSES = %w[draft published suspended].freeze
  CREATION_SOURCES = %w[self_service external].freeze
  INITIAL_REVISION_FIELDS = %i[
    display_name headline bio years_experience whatsapp_e164 instagram_url youtube_url
  ].freeze

  belongs_to :user_account
  belongs_to :working_revision, class_name: "ProfessionalProfileRevision", optional: true
  belongs_to :published_revision, class_name: "ProfessionalProfileRevision", optional: true
  has_many :revisions,
    class_name: "ProfessionalProfileRevision",
    inverse_of: :professional_profile,
    dependent: :destroy
  has_many :portfolio_items, dependent: :destroy
  has_many :verification_requests, dependent: :destroy
  has_many :profile_photos,
    class_name: "ProfessionalProfilePhoto",
    dependent: :destroy
  belongs_to :profile_photo, class_name: "ProfessionalProfilePhoto", optional: true
  has_many :media_uploads, dependent: :destroy
  has_many :daily_metrics,
    class_name: "ProfessionalDailyMetric",
    foreign_key: :professional_id,
    inverse_of: :professional,
    dependent: :restrict_with_exception
  has_many :daily_activities,
    class_name: "ProfessionalDailyActivity",
    foreign_key: :professional_id,
    inverse_of: :professional,
    dependent: :restrict_with_exception
  has_many :quotes,
    foreign_key: :professional_id,
    inverse_of: :professional,
    dependent: :restrict_with_exception
  has_many :customers,
    foreign_key: :professional_id,
    inverse_of: :professional,
    dependent: :restrict_with_exception
  has_many :service_jobs, through: :quotes
  has_many :initiated_relationships,
    class_name: "ProfessionalRelationship",
    foreign_key: :initiator_professional_id,
    inverse_of: :initiator_professional,
    dependent: :restrict_with_exception
  has_many :received_relationships,
    class_name: "ProfessionalRelationship",
    foreign_key: :recipient_professional_id,
    inverse_of: :recipient_professional,
    dependent: :restrict_with_exception
  attr_writer(*INITIAL_REVISION_FIELDS)

  validates :display_name, length: {in: 3..70}, on: :create
  validates :headline, length: {in: 1..120}, allow_nil: true, on: :create
  validates :bio, length: {in: 1..2500}, allow_nil: true, on: :create
  validates :years_experience, numericality: {only_integer: true, in: 0..70}, allow_nil: true, on: :create
  validates :whatsapp_e164, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}, allow_nil: true, on: :create
  validates :profile_status, inclusion: {in: STATUSES}
  validates :creation_source, inclusion: {in: CREATION_SOURCES}
  validate :birthdate_is_plausible
  validates :public_slug, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}, uniqueness: true
  validate :initial_social_urls_are_canonical, on: :create
  validate :revision_pointers_belong_to_profile
  validate :photo_pointers_belong_to_profile
  validate :published_at_is_immutable, on: :update
  validate :creation_source_is_immutable, on: :update

  before_validation :normalize_initial_fields, on: :create
  before_validation :assign_public_slug, on: :create
  after_create :create_initial_revision!

  scope :publicly_eligible, -> {
    joins(:user_account, :published_revision, :profile_photo)
      .where(profile_status: "published", user_accounts: {status: "active"})
      .where(professional_profile_revisions: {profile_type: "self_service"})
      .where.not(birthdate: nil)
      .where(professional_profile_photos: {deleted_at: nil})
      .where(<<~SQL.squish)
        EXISTS (
          SELECT 1
          FROM professional_profile_services eligible_services
          INNER JOIN services eligible_service_catalog
            ON eligible_service_catalog.id = eligible_services.service_id
          INNER JOIN service_categories eligible_service_categories
            ON eligible_service_categories.id = eligible_service_catalog.category_id
          WHERE eligible_services.professional_profile_revision_id = professional_profiles.published_revision_id
            AND eligible_services.is_primary = TRUE
            AND eligible_service_catalog.is_active = TRUE
            AND eligible_service_categories.is_active = TRUE
        )
      SQL
      .where(<<~SQL.squish)
        professional_profile_revisions.coverage_city_code IS NOT NULL
        AND (
          professional_profile_revisions.covers_whole_city = TRUE
          OR EXISTS (
            SELECT 1
            FROM professional_profile_service_areas eligible_areas
            INNER JOIN neighborhoods eligible_neighborhoods
              ON eligible_neighborhoods.code = eligible_areas.neighborhood_code
            WHERE eligible_areas.professional_profile_revision_id = professional_profiles.published_revision_id
              AND eligible_neighborhoods.city_code = professional_profile_revisions.coverage_city_code
          )
        )
      SQL
  }

  scope :externally_eligible, -> {
    joins(:user_account, :published_revision)
      .where(
        profile_status: "published",
        creation_source: "external",
        user_accounts: {status: "active"},
        professional_profile_revisions: {profile_type: "external"}
      )
      .where.not(external_published_at: nil)
      .where(<<~SQL.squish)
        user_accounts.registered_at IS NOT NULL OR EXISTS (
          SELECT 1
          FROM professional_relationships external_relationships
          WHERE external_relationships.recipient_professional_id = professional_profiles.id
            AND external_relationships.source = 'external_phone'
            AND external_relationships.contact_publication_attested_at IS NOT NULL
            AND external_relationships.deleted_at IS NULL
            AND external_relationships.status IN ('pending', 'accepted')
        )
      SQL
  }

  scope :publicly_viewable, -> {
    where(id: publicly_eligible.select(:id)).or(where(id: externally_eligible.select(:id)))
  }

  scope :publicly_searchable, -> {
    publicly_viewable
      .joins(:published_revision)
      .where(<<~SQL.squish)
        EXISTS (
          SELECT 1
          FROM professional_profile_services searchable_services
          WHERE searchable_services.professional_profile_revision_id = professional_profiles.published_revision_id
        )
      SQL
      .where.not(professional_profile_revisions: {coverage_city_code: nil})
      .where(<<~SQL.squish)
        professional_profile_revisions.covers_whole_city = TRUE OR EXISTS (
          SELECT 1
          FROM professional_profile_service_areas searchable_areas
          WHERE searchable_areas.professional_profile_revision_id = professional_profiles.published_revision_id
        )
      SQL
  }

  def publication_blockers
    revision = working_revision
    photo = profile_photo
    blockers = []
    blockers << "identity" unless revision&.display_name.present? && birthdate.present? && user_account.phone_e164.present?
    blockers << "photo" unless photo && photo.deleted_at.nil?
    blockers << "services" unless revision_services_complete?(revision)
    blockers << "coverage" unless revision_coverage_complete?(revision)
    blockers
  end

  def publicly_available?
    external_presentation? ? externally_available? : self_service_publicly_available?
  end

  def self_service_publicly_available?
    profile_status == "published" &&
      user_account.active? &&
      published_revision&.self_service? &&
      profile_photo.present? &&
      profile_photo.deleted_at.nil? &&
      self_service_publication_blockers.empty?
  end

  def search_eligible?
    publicly_available? && published_revision.professional_profile_services.exists?
  end

  def external_presentation?
    published_revision&.external? == true
  end

  def externally_available?
    return false unless profile_status == "published" && creation_source == "external"
    return false unless user_account.active? && external_published_at.present?
    return false unless published_revision&.external?
    return true if user_account.registered?

    received_relationships.active
      .where(source: "external_phone", status: %w[pending accepted])
      .where.not(contact_publication_attested_at: nil)
      .exists?
  end

  def has_self_service_publication?
    published_revision&.self_service? == true
  end

  def suspension_reason
    return unless profile_status == "suspended"

    ModerationAction
      .where(target_type: "professional_profile", target_id: id, action: "hidden")
      .order(created_at: :desc, id: :desc)
      .pick(:reason)
  end

  INITIAL_REVISION_FIELDS.each do |field|
    define_method(field) do
      working_revision&.public_send(field) || instance_variable_get("@#{field}")
    end
  end

  private

  def normalize_initial_fields
    @display_name = @display_name.to_s.squish
    @headline = @headline.to_s.squish.presence
    @bio = @bio.to_s.squish.presence
    @whatsapp_e164 = @whatsapp_e164.to_s.strip.presence
    @instagram_url = @instagram_url.to_s.strip.presence
    @youtube_url = @youtube_url.to_s.strip.presence
  end

  def assign_public_slug
    return if public_slug.present?

    base = @display_name.to_s.parameterize.presence || "profissional"
    self.public_slug = base
    self.public_slug = "#{base}-#{SecureRandom.hex(3)}" if self.class.exists?(public_slug:)
  end

  def create_initial_revision!
    revision = revisions.create!(
      version: 1,
      profile_type: "self_service",
      **INITIAL_REVISION_FIELDS.index_with { |field| instance_variable_get("@#{field}") }
    )
    update_column(:working_revision_id, revision.id)
    self.working_revision = revision
  end

  def initial_social_urls_are_canonical
    errors.add(:instagram_url, :invalid) unless SocialProfileUrl.canonical?(@instagram_url, platform: :instagram)
    errors.add(:youtube_url, :invalid) unless SocialProfileUrl.canonical?(@youtube_url, platform: :youtube)
  end

  def revision_pointers_belong_to_profile
    [working_revision, published_revision].compact.each do |revision|
      errors.add(:base, :invalid) unless revision.professional_profile_id == id
    end
  end

  def photo_pointers_belong_to_profile
    return unless profile_photo

    errors.add(:base, :invalid) unless profile_photo.professional_profile_id == id
  end

  def published_at_is_immutable
    return unless published_at_was.present? && will_save_change_to_published_at?

    errors.add(:published_at, :readonly)
  end

  def creation_source_is_immutable
    return unless will_save_change_to_creation_source?

    errors.add(:creation_source, :readonly)
  end

  def birthdate_is_plausible
    return if birthdate.blank?
    return if birthdate.between?(120.years.ago.to_date, Date.current)

    errors.add(:birthdate, :invalid)
  end

  def revision_services_complete?(revision)
    return false unless revision

    selections = revision.professional_profile_services.includes(service: :category).to_a
    selections.any? &&
      selections.count(&:is_primary?) == 1 &&
      selections.all? { |selection| selection.service.is_active? && selection.service.category.is_active? }
  end

  def self_service_publication_blockers
    revision = published_revision
    photo = profile_photo
    blockers = []
    blockers << "identity" unless revision&.display_name.present? && birthdate.present? && user_account.phone_e164.present?
    blockers << "photo" unless photo && photo.deleted_at.nil?
    blockers << "services" unless revision_services_complete?(revision)
    blockers << "coverage" unless revision_coverage_complete?(revision)
    blockers
  end

  def revision_coverage_complete?(revision)
    return false unless revision&.coverage_city

    areas = revision.professional_profile_service_areas.includes(:neighborhood).to_a
    return areas.empty? if revision.covers_whole_city?
    return false if areas.empty?

    areas.all? { |area| area.neighborhood&.city_code == revision.coverage_city_code }
  end
end
