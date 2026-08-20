# frozen_string_literal: true

class ProfessionalRelationship < ApplicationRecord
  TYPES = %w[recommendation worked_together].freeze
  STATUSES = %w[pending accepted declined].freeze

  belongs_to :initiator_professional, class_name: "ProfessionalProfile"
  belongs_to :recipient_professional, class_name: "ProfessionalProfile"

  validates :relationship_type, inclusion: {in: TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :context_note, length: {in: 1..300}, allow_nil: true
  validates :relationship_type,
    uniqueness: {scope: %i[initiator_professional_id recipient_professional_id]}
  validate :profiles_are_distinct
  validate :response_matches_status

  before_validation :normalize_context_note

  private

  def normalize_context_note
    self.context_note = context_note.to_s.squish.presence
  end

  def profiles_are_distinct
    return if initiator_professional_id.blank? || recipient_professional_id.blank?
    return unless initiator_professional_id == recipient_professional_id

    errors.add(:recipient_professional, :invalid)
  end

  def response_matches_status
    if status == "pending"
      errors.add(:responded_at, :invalid) if responded_at.present?
    elsif responded_at.blank?
      errors.add(:responded_at, :blank)
    end
  end
end
