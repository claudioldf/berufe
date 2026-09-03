# frozen_string_literal: true

class ProfessionalDailyMetric < ApplicationRecord
  PRODUCT_TIME_ZONE = "America/Sao_Paulo"
  COUNTERS = %i[
    profile_views
    whatsapp_clicks
    whatsapp_clicks_public_profile
    whatsapp_clicks_search_result
    quotes_shared
  ].freeze
  WHATSAPP_SOURCE_COLUMNS = {
    "public_profile" => "whatsapp_clicks_public_profile",
    "search_result" => "whatsapp_clicks_search_result"
  }.freeze

  belongs_to :professional, class_name: "ProfessionalProfile", inverse_of: :daily_metrics

  validates :metric_date, presence: true, uniqueness: {scope: :professional_id}
  validates(*COUNTERS, numericality: {only_integer: true, greater_than_or_equal_to: 0})
  validate :whatsapp_total_matches_sources

  def self.increment_profile_views!(professional_id:, occurred_at: Time.current)
    metric = find_or_create_counter_row!(professional_id:, occurred_at:)
    where(id: metric.id).update_all(
      "profile_views = profile_views + 1, updated_at = CURRENT_TIMESTAMP"
    )
    metric.reload
  end

  def self.increment_whatsapp_clicks!(professional_id:, source:, occurred_at: Time.current)
    source_column = WHATSAPP_SOURCE_COLUMNS.fetch(source)
    metric = find_or_create_counter_row!(professional_id:, occurred_at:)
    where(id: metric.id).update_all(<<~SQL.squish)
      whatsapp_clicks = whatsapp_clicks + 1,
      #{source_column} = #{source_column} + 1,
      updated_at = CURRENT_TIMESTAMP
    SQL
    metric.reload
  end

  def self.increment_quote_shares!(professional_id:, occurred_at: Time.current)
    # Delegated administrator support work is not professional engagement.
    return if Current.delegated_request?

    metric = find_or_create_counter_row!(professional_id:, occurred_at:)
    where(id: metric.id).update_all(
      "quotes_shared = quotes_shared + 1, updated_at = CURRENT_TIMESTAMP"
    )
    metric.reload
  end

  def self.find_or_create_counter_row!(professional_id:, occurred_at:)
    metric_date = occurred_at.in_time_zone(PRODUCT_TIME_ZONE).to_date
    insert_all(
      [{professional_id:, metric_date:}],
      unique_by: :index_professional_daily_metrics_on_professional_and_date
    )
    find_by!(professional_id:, metric_date:)
  end
  private_class_method :find_or_create_counter_row!

  private

  def whatsapp_total_matches_sources
    return if whatsapp_clicks == whatsapp_clicks_public_profile + whatsapp_clicks_search_result

    errors.add(:whatsapp_clicks, :invalid)
  end
end
