# frozen_string_literal: true

class ProfessionalQuoteSummaryQuery
  PRODUCT_TIME_ZONE = ProfessionalDailyActivity::PRODUCT_TIME_ZONE

  Result = Data.define(
    :awaiting_response_count,
    :awaiting_response_total_amount,
    :changes_requested_count,
    :approved_this_month_count,
    :approved_this_month_total_amount
  )

  def call(scope:, now: Time.current)
    local_month = now.in_time_zone(PRODUCT_TIME_ZONE).beginning_of_month
    approved_condition = ActiveRecord::Base.sanitize_sql_array([
      "quotes.status IN (?) AND quotes.customer_decided_at >= ? AND quotes.customer_decided_at < ?",
      Quote::LOCKED_STATUSES,
      local_month,
      local_month.next_month
    ])

    values = scope.unscope(:order).pick(
      Arel.sql("COUNT(*) FILTER (WHERE quotes.status = 'shared')"),
      Arel.sql("COALESCE(SUM(quotes.total_amount) FILTER (WHERE quotes.status = 'shared'), 0)"),
      Arel.sql("COUNT(*) FILTER (WHERE quotes.status = 'change_requested')"),
      Arel.sql("COUNT(*) FILTER (WHERE #{approved_condition})"),
      Arel.sql("COALESCE(SUM(quotes.total_amount) FILTER (WHERE #{approved_condition}), 0)")
    )

    Result.new(
      awaiting_response_count: values.fetch(0).to_i,
      awaiting_response_total_amount: BigDecimal(values.fetch(1).to_s),
      changes_requested_count: values.fetch(2).to_i,
      approved_this_month_count: values.fetch(3).to_i,
      approved_this_month_total_amount: BigDecimal(values.fetch(4).to_s)
    )
  end
end
