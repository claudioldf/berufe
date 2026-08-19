# frozen_string_literal: true

class SearchDailyRollup < ApplicationRecord
  COUNTERS = %i[
    searches with_results with_three_results with_profile_open
    with_whatsapp_handoff zero_results thin_results
  ].freeze

  belongs_to :service, optional: true
  belongs_to :neighborhood,
    primary_key: :code,
    foreign_key: :neighborhood_code,
    optional: true

  validates :report_date, presence: true
  validates(*COUNTERS, numericality: {only_integer: true, greater_than_or_equal_to: 0})
  validate :matched_or_unmatched_dimension

  private

  def matched_or_unmatched_dimension
    return if service_id.present? ^ unmatched_query.present?

    errors.add(:base, :invalid)
  end
end
