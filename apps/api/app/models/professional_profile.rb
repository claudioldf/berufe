# frozen_string_literal: true

class ProfessionalProfile < ApplicationRecord
  STATUSES = %w[draft pending_review published suspended].freeze
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
  has_many :media_uploads, dependent: :destroy
  has_many :portfolio_items, dependent: :destroy
  has_many :verification_requests, dependent: :destroy
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
  has_many :profile_photos,
    class_name: "ProfessionalProfilePhoto",
    dependent: :destroy
  belongs_to :working_photo, class_name: "ProfessionalProfilePhoto", optional: true
  belongs_to :published_photo, class_name: "ProfessionalProfilePhoto", optional: true

  attr_writer(*INITIAL_REVISION_FIELDS)

  validates :display_name, length: {in: 3..70}, on: :create
  validates :headline, length: {in: 1..120}, allow_nil: true, on: :create
  validates :bio, length: {in: 1..500}, allow_nil: true, on: :create
  validates :years_experience, numericality: {only_integer: true, in: 0..70}, allow_nil: true, on: :create
  validates :whatsapp_e164, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}, allow_nil: true, on: :create
  validates :profile_status, inclusion: {in: STATUSES}
  validates :public_slug, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}, uniqueness: true
  validate :initial_social_urls_are_canonical, on: :create
  validate :revision_pointers_belong_to_profile
  validate :photo_pointers_belong_to_profile

  before_validation :normalize_initial_fields, on: :create
  before_validation :assign_public_slug, on: :create
  after_create :create_initial_revision!

  scope :publicly_eligible, -> {
    joins(:user_account, :published_revision)
      .where(profile_status: "published", user_accounts: {status: "active"})
      .where(professional_profile_revisions: {status: "approved"})
  }

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
    [working_revision, published_revision].compact.each do |revision|
      errors.add(:base, :invalid) unless revision.professional_profile_id == id
    end
  end

  def photo_pointers_belong_to_profile
    [working_photo, published_photo].compact.each do |photo|
      errors.add(:base, :invalid) unless photo.professional_profile_id == id
    end
  end
end
