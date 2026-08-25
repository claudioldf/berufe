# frozen_string_literal: true

class SearchReportingRetentionJob < ApplicationJob
  queue_as :default

  TIME_ZONE = "America/Sao_Paulo"

  def perform(now: Time.current)
    scrub_llm_audits!(now:)
    today = now.in_time_zone(TIME_ZONE).to_date
    retained_from = today - (Rails.configuration.x.berufe.reporting.raw_search_retention_days - 1)
    aggregate_dates = SearchEvent.where(created_at: ...retained_from.in_time_zone(TIME_ZONE))
      .distinct
      .pluck(Arel.sql("(created_at AT TIME ZONE 'America/Sao_Paulo')::date"))
      .sort
    aggregate_dates.each { |date| aggregate_and_purge!(Date.parse(date.to_s)) }

    aggregate_from = today - (Rails.configuration.x.berufe.reporting.aggregate_retention_days - 1)
    SearchDailyRollup.where(report_date: ...aggregate_from).delete_all
    ProfessionalDailyMetric.where(metric_date: ...aggregate_from).delete_all
    ProfessionalDailyActivity.where(activity_date: ...aggregate_from).delete_all
    LlmSearchAnalysis.where(expires_at: ..now).delete_all
    PublicSearchRateLimitCounter
      .where(window_started_at: ...(now - PublicSearchRateLimiter::WINDOW))
      .delete_all
  end

  private

  def scrub_llm_audits!(now:)
    retained_after = now - Rails.configuration.x.berufe.reporting.llm_search_audit_retention_days.days
    SearchEvent.llm_audits
      .where(created_at: ...retained_after)
      .update_all(
        input_prompt: nil,
        raw_llm_response: nil,
        parsed_response: nil,
        response_source: nil,
        llm_adapter: nil,
        llm_model: nil,
        llm_provider_request_id: nil,
        llm_prompt_digest: nil,
        updated_at: now
      )
  end

  def aggregate_and_purge!(date)
    range = date.in_time_zone(TIME_ZONE)...(date + 1).in_time_zone(TIME_ZONE)
    SearchEvent.transaction do
      relation = SearchEvent.where(created_at: range)
      locked_ids = relation.lock.pluck(:id)
      return if locked_ids.empty?

      relation = SearchEvent.where(id: locked_ids)
      reportable_relation = relation.reportable

      rows = reportable_relation.group(:service_id, :neighborhood_code)
        .group(Arel.sql("CASE WHEN service_id IS NULL THEN query_text_normalized END"))
        .pluck(
          :service_id,
          :neighborhood_code,
          Arel.sql("CASE WHEN service_id IS NULL THEN query_text_normalized END"),
          Arel.sql("COUNT(*)"),
          Arel.sql("COUNT(*) FILTER (WHERE result_count > 0)"),
          Arel.sql("COUNT(*) FILTER (WHERE result_count >= 3)"),
          Arel.sql("COUNT(*) FILTER (WHERE profile_opened)"),
          Arel.sql("COUNT(*) FILTER (WHERE whatsapp_handoff_occurred)"),
          Arel.sql("COUNT(*) FILTER (WHERE result_count = 0)"),
          Arel.sql("COUNT(*) FILTER (WHERE result_count BETWEEN 1 AND 2)")
        )
      SearchDailyRollup.where(report_date: date).delete_all
      rollups = rows.map do |service_id, neighborhood_code, unmatched_query, *counts|
        {
          report_date: date,
          service_id:,
          neighborhood_code:,
          unmatched_query:,
          searches: counts[0],
          with_results: counts[1],
          with_three_results: counts[2],
          with_profile_open: counts[3],
          with_whatsapp_handoff: counts[4],
          zero_results: counts[5],
          thin_results: counts[6]
        }
      end
      SearchDailyRollup.insert_all!(rollups) if rollups.any?
      relation.delete_all
    end
  end
end
