# frozen_string_literal: true

class ProfessionalRelationship < ApplicationRecord
  TYPES = %w[recommendation worked_together].freeze
  STATUSES = %w[pending accepted declined].freeze
  SOURCES = %w[existing_profile external_phone].freeze

  belongs_to :initiator_professional, class_name: "ProfessionalProfile"
  belongs_to :recipient_professional, class_name: "ProfessionalProfile"

  scope :active, -> { where(deleted_at: nil) }

  validates :relationship_type, inclusion: {in: TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :source, inclusion: {in: SOURCES}
  validates :context_note, length: {in: 1..300}, allow_nil: true
  validates :relationship_type,
    uniqueness: {
      scope: %i[initiator_professional_id recipient_professional_id],
      conditions: -> { where(deleted_at: nil) }
    }
  validate :profiles_are_distinct
  validate :response_matches_status
  validate :external_source_has_attestation

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

  def external_source_has_attestation
    return unless source == "external_phone" && contact_publication_attested_at.blank?

    errors.add(:contact_publication_attested_at, :blank)
  end
end
