# frozen_string_literal: true

class SearchEvent < ApplicationRecord
  JOINVILLE = "Joinville"
  MAXIMUM_RETAINED_QUERY_LENGTH = 80

  belongs_to :service, optional: true
  belongs_to :neighborhood,
    primary_key: :code,
    foreign_key: :neighborhood_code,
    optional: true

  validates :city_code, inclusion: {in: [JOINVILLE]}
  validates :query_text_normalized,
    length: {maximum: MAXIMUM_RETAINED_QUERY_LENGTH},
    allow_nil: true
  validates :result_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :profile_opened, :whatsapp_handoff_occurred, inclusion: {in: [true, false]}
  validate :retained_query_is_normalized

  private

  def retained_query_is_normalized
    return if query_text_normalized.nil?
    return if query_text_normalized.present? && PublicSearchText.normalize(query_text_normalized) == query_text_normalized

    errors.add(:query_text_normalized, :invalid)
  end
end
