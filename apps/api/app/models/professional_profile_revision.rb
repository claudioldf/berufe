# frozen_string_literal: true

class ProfessionalProfileRevision < ApplicationRecord
  STATUSES = %w[draft pending_review approved rejected superseded].freeze
  PROFILE_TYPES = %w[self_service external].freeze
  # The fields that reach the public projection. Only a change to one of these
  # is a "material edit" in Feature Plan A2 §3.8, so only these send an already
  # published profile back to moderation.
  MATERIAL_FIELDS = %i[
    display_name headline bio years_experience whatsapp_e164 instagram_url youtube_url
  ].freeze

  belongs_to :professional_profile, inverse_of: :revisions
  has_many :professional_profile_services, dependent: :destroy
  has_many :services, through: :professional_profile_services
  has_many :professional_profile_service_areas, dependent: :destroy

  validates :version, numericality: {only_integer: true, greater_than: 0}, uniqueness: {scope: :professional_profile_id}
  validates :status, inclusion: {in: STATUSES}
  validates :profile_type, inclusion: {in: PROFILE_TYPES}
  validates :display_name, length: {in: 3..70}
  validates :headline, length: {in: 1..120}, allow_nil: true
  validates :bio, length: {in: 1..500}, allow_nil: true
  validates :years_experience, numericality: {only_integer: true, in: 0..70}, allow_nil: true
  validates :whatsapp_e164, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}, allow_nil: true
  validates :instagram_url, length: {maximum: 200}, allow_nil: true
  validates :youtube_url, length: {maximum: 200}, allow_nil: true
  validate :social_urls_are_canonical

  before_validation :normalize_fields

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  PROFILE_TYPES.each do |known_type|
    define_method("#{known_type}?") { profile_type == known_type }
  end

  def editable?
    status.in?(%w[draft pending_review rejected])
  end

  # Comparable value of everything the public sees, so two revisions can be
  # checked for a material difference.
  def material_snapshot
    MATERIAL_FIELDS.index_with { |field| public_send(field) }.merge(
      services: professional_profile_services.reload.map do |selection|
        [selection.service_id, selection.is_primary?, selection.note.to_s]
      end.sort,
      areas: professional_profile_service_areas.reload.map do |area|
        [area.city_code.to_s, area.neighborhood_code.to_s]
      end.sort
    )
  end

  private

  def normalize_fields
    self.display_name = display_name.to_s.squish
    self.headline = headline.to_s.squish.presence
    self.bio = bio.to_s.squish.presence
    self.whatsapp_e164 = whatsapp_e164.to_s.strip.presence
    self.instagram_url = instagram_url.to_s.strip.presence
    self.youtube_url = youtube_url.to_s.strip.presence
  end

  def social_urls_are_canonical
    errors.add(:instagram_url, :invalid) unless SocialProfileUrl.canonical?(instagram_url, platform: :instagram)
    errors.add(:youtube_url, :invalid) unless SocialProfileUrl.canonical?(youtube_url, platform: :youtube)
  end
end
