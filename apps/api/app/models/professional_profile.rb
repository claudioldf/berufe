# frozen_string_literal: true

class ProfessionalProfile < ApplicationRecord
  STATUSES = %w[draft pending_review published suspended].freeze

  belongs_to :user_account

  validates :display_name, length: {in: 3..70}
  validates :headline, length: {in: 1..120}, allow_nil: true
  validates :bio, length: {in: 1..500}, allow_nil: true
  validates :years_experience, numericality: {only_integer: true, in: 0..70}, allow_nil: true
  validates :whatsapp_e164, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}, allow_nil: true
  validates :instagram_url, length: {maximum: 200}, allow_nil: true
  validates :youtube_url, length: {maximum: 200}, allow_nil: true
  validates :profile_status, inclusion: {in: STATUSES}
  validate :social_urls_are_canonical

  before_validation :normalize_text_fields

  private

  def normalize_text_fields
    self.display_name = display_name.to_s.squish
    self.headline = headline.to_s.squish.presence
    self.bio = bio.to_s.squish.presence
    self.whatsapp_e164 = whatsapp_e164.to_s.strip.presence
    self.instagram_url = instagram_url.to_s.strip.presence
    self.youtube_url = youtube_url.to_s.strip.presence
  end

  def social_urls_are_canonical
    unless SocialProfileUrl.canonical?(instagram_url, platform: :instagram)
      errors.add(:instagram_url, :invalid)
    end
    unless SocialProfileUrl.canonical?(youtube_url, platform: :youtube)
      errors.add(:youtube_url, :invalid)
    end
  end
end
