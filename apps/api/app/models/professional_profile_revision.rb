# frozen_string_literal: true

class ProfessionalProfileRevision < ApplicationRecord
  PROFILE_TYPES = %w[self_service external].freeze

  belongs_to :professional_profile, inverse_of: :revisions
  belongs_to :coverage_city,
    class_name: "City",
    foreign_key: :coverage_city_code,
    optional: true
  has_many :professional_profile_services, dependent: :destroy
  has_many :services, through: :professional_profile_services
  has_many :professional_profile_service_areas, dependent: :destroy

  validates :version, numericality: {only_integer: true, greater_than: 0}, uniqueness: {scope: :professional_profile_id}
  validates :profile_type, inclusion: {in: PROFILE_TYPES}
  validates :covers_whole_city, inclusion: {in: [true, false]}
  validates :display_name, length: {in: 3..70}
  validates :headline, length: {in: 1..120}, allow_nil: true
  validates :bio, length: {in: 1..2500}, allow_nil: true
  validates :ai_headline, length: {in: 1..120}, allow_nil: true
  validates :ai_bio, length: {in: 1..500}, allow_nil: true
  validates :years_experience, numericality: {only_integer: true, in: 0..70}, allow_nil: true
  validates :whatsapp_e164, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}, allow_nil: true
  validates :instagram_url, length: {maximum: 200}, allow_nil: true
  validates :youtube_url, length: {maximum: 200}, allow_nil: true
  validate :social_urls_are_canonical

  before_validation :normalize_fields

  PROFILE_TYPES.each do |known_type|
    define_method("#{known_type}?") { profile_type == known_type }
  end

  private

  def normalize_fields
    self.display_name = display_name.to_s.squish
    self.headline = headline.to_s.squish.presence
    self.bio = bio.to_s.squish.presence
    self.ai_headline = ai_headline.to_s.squish.presence
    self.ai_bio = ai_bio.to_s.squish.presence
    self.whatsapp_e164 = whatsapp_e164.to_s.strip.presence
    self.instagram_url = instagram_url.to_s.strip.presence
    self.youtube_url = youtube_url.to_s.strip.presence
  end

  def social_urls_are_canonical
    errors.add(:instagram_url, :invalid) unless SocialProfileUrl.canonical?(instagram_url, platform: :instagram)
    errors.add(:youtube_url, :invalid) unless SocialProfileUrl.canonical?(youtube_url, platform: :youtube)
  end
end
