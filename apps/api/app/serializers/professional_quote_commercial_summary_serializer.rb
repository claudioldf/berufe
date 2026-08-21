# frozen_string_literal: true

class ProfessionalQuoteCommercialSummarySerializer
  def initialize(summary)
    @summary = summary
  end

  def as_json(*)
    {
      awaiting_response: {
        count: summary.awaiting_response_count,
        total_amount: money(summary.awaiting_response_total_amount)
      },
      changes_requested: {
        count: summary.changes_requested_count
      },
      approved_this_month: {
        count: summary.approved_this_month_count,
        total_amount: money(summary.approved_this_month_total_amount)
      }
    }
  end

  private

  attr_reader :summary

  def money(value)
    format("%.2f", value)
  end
end
