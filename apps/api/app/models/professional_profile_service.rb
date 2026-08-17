# frozen_string_literal: true

class ProfessionalProfileService < ApplicationRecord
  belongs_to :professional_profile_revision
  belongs_to :service

  validates :service_id, uniqueness: {scope: :professional_profile_revision_id}
  validates :is_primary, inclusion: {in: [true, false]}
  validates :note, length: {in: 1..120}, allow_nil: true

  before_validation :normalize_note

  private

  def normalize_note
    self.note = note.to_s.squish.presence
  end
end
