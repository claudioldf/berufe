# frozen_string_literal: true

class ProfessionalProfile < ApplicationRecord
  STATUSES = %w[draft pending_review published suspended].freeze

  belongs_to :user_account

  validates :display_name, length: {in: 3..70}
  validates :profile_status, inclusion: {in: STATUSES}

  before_validation :normalize_display_name

  private

  def normalize_display_name
    self.display_name = display_name.to_s.squish
  end
end
