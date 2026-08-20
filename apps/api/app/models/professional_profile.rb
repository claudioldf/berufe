# frozen_string_literal: true

class ProfessionalProfile < ApplicationRecord
  STATUSES = %w[draft pending_review published suspended].freeze
  INITIAL_REVISION_FIELDS = %i[
    display_name headline bio years_experience whatsapp_e164 instagram_url youtube_url
  ].freeze

  belongs_to :user_account
  belongs_to :working_revision, class_name: "ProfessionalProfileRevision", optional: true
  belongs_to :published_revision, class_name: "ProfessionalProfileRevision", optional: true
  belongs_to :approved_revision, class_name: "ProfessionalProfileRevision", optional: true
  has_many :revisions,
    class_name: "ProfessionalProfileRevision",
    inverse_of: :professional_profile,
    dependent: :destroy
  has_many :portfolio_items, dependent: :destroy
  has_many :verification_requests, dependent: :destroy
  has_many :profile_photos,
    class_name: "ProfessionalProfilePhoto",
    dependent: :destroy
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
  belongs_to :working_photo, class_name: "ProfessionalProfilePhoto", optional: true
  belongs_to :published_photo, class_name: "ProfessionalProfilePhoto", optional: true
  belongs_to :approved_photo, class_name: "ProfessionalProfilePhoto", optional: true

  attr_writer(*INITIAL_REVISION_FIELDS)

  validates :display_name, length: {in: 3..70}, on: :create
  validates :headline, length: {in: 1..120}, allow_nil: true, on: :create
  validates :bio, length: {in: 1..500}, allow_nil: true, on: :create
  validates :years_experience, numericality: {only_integer: true, in: 0..70}, allow_nil: true, on: :create
  validates :whatsapp_e164, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}, allow_nil: true, on: :create
  validates :profile_status, inclusion: {in: STATUSES}
  validate :birthdate_is_plausible
  validates :public_slug, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}, uniqueness: true
  validate :initial_social_urls_are_canonical, on: :create
  validate :revision_pointers_belong_to_profile
  validate :photo_pointers_belong_to_profile
  validate :published_at_is_immutable, on: :update

  before_validation :normalize_initial_fields, on: :create
  before_validation :assign_public_slug, on: :create
  after_create :create_initial_revision!

  scope :publicly_eligible, -> {
    joins(:user_account, :published_revision, :published_photo)
      .where(profile_status: "published", user_accounts: {status: "active"})
      .where.not(birthdate: nil)
      .where(professional_profile_revisions: {status: %w[pending_review approved]})
      .where(professional_profile_photos: {status: %w[pending_review approved]})
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
        EXISTS (
          SELECT 1
          FROM professional_profile_service_areas eligible_areas
          LEFT JOIN neighborhoods eligible_neighborhoods
            ON eligible_neighborhoods.code = eligible_areas.neighborhood_code
          WHERE eligible_areas.professional_profile_revision_id = professional_profiles.published_revision_id
            AND (
              eligible_areas.neighborhood_code IS NULL OR
              eligible_neighborhoods.is_active = TRUE
            )
        )
      SQL
  }

  def publication_blockers
    revision = (profile_status == "published") ? published_revision : working_revision
    photo = (profile_status == "published") ? published_photo : working_photo
    blockers = []
    blockers << "identity" unless revision&.display_name.present? && birthdate.present? && user_account.phone_e164.present?
    blockers << "photo" unless photo&.status&.in?(%w[pending_review approved])
    blockers << "services" unless revision_services_complete?(revision)
    blockers << "coverage" unless revision_coverage_complete?(revision)
    blockers
  end

  def publicly_available?
    profile_status == "published" &&
      user_account.active? &&
      published_revision&.status&.in?(%w[pending_review approved]) &&
      published_photo&.status&.in?(%w[pending_review approved]) &&
      publication_blockers.empty?
  end

  def search_eligible?
    publicly_available?
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
      status: "draft",
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
    [working_revision, published_revision, approved_revision].compact.each do |revision|
      errors.add(:base, :invalid) unless revision.professional_profile_id == id
    end
  end

  def photo_pointers_belong_to_profile
    [working_photo, published_photo, approved_photo].compact.each do |photo|
      errors.add(:base, :invalid) unless photo.professional_profile_id == id
    end
  end

  def published_at_is_immutable
    return unless published_at_was.present? && will_save_change_to_published_at?

    errors.add(:published_at, :readonly)
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

  def revision_coverage_complete?(revision)
    return false unless revision

    areas = revision.professional_profile_service_areas.includes(:neighborhood).to_a
    return false if areas.empty?
    return true if areas.one? && areas.first.neighborhood_code.nil?

    areas.all? { |area| area.neighborhood_code.present? && area.neighborhood&.is_active? }
  end
end
