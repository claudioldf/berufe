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
  validate :dimensions_do_not_conflict

  private

  def dimensions_do_not_conflict
    return unless service_id.present? && unmatched_query.present?

    errors.add(:base, :invalid)
  end
end
