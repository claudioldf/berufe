# frozen_string_literal: true

module Admin
  module Reports
    class SearchAggregate
      Counter = Struct.new(
        :service_id, :neighborhood_code, :unmatched_query,
        :searches, :with_results, :with_three_results, :with_profile_open,
        :with_whatsapp_handoff, :zero_results, :thin_results
      )

      attr_reader :rows

      def initialize(start_at:, end_at:)
        @start_at = start_at
        @end_at = end_at
        @rows = combine(raw_rows + rollup_rows)
      end

      def totals
        rows.each_with_object(Counter.new(**Counter.members.index_with { 0 })) do |row, total|
          Counter.members.drop(3).each { |field| total[field] += row[field] }
        end
      end

      private

      attr_reader :start_at, :end_at

      def raw_rows
        SearchEvent.where(created_at: start_at...end_at)
          .group(:service_id, :neighborhood_code)
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
          ).map { |values| build(values) }
      end

      def rollup_rows
        SearchDailyRollup.where(report_date: start_at.to_date...end_at.to_date).map do |row|
          Counter.new(**Counter.members.index_with { |field| row.public_send(field) })
        end
      end

      def build(values)
        Counter.new(**Counter.members.zip(values).to_h)
      end

      def combine(all_rows)
        all_rows.group_by { |row| [row.service_id, row.neighborhood_code, row.unmatched_query] }.map do |key, grouped|
          Counter.new(
            service_id: key[0],
            neighborhood_code: key[1],
            unmatched_query: key[2],
            **Counter.members.drop(3).index_with { |field| grouped.sum { |row| row[field].to_i } }
          )
        end
      end
    end
  end
end
