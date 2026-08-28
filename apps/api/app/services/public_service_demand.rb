# frozen_string_literal: true

# 30-day search demand for one service in one city, released only above a
# privacy threshold -- the same principle the admin growth report's
# coverage-gap surface uses (Admin::Reports::Period#threshold), applied
# here to a number shown to the public. A handful of searches in a small
# city could narrow down to one household; below the threshold, nothing is
# released at all, not even a rounded or fuzzed value.
#
# Combines not-yet-rolled-up SearchEvent rows with SearchDailyRollup sums,
# mirroring Admin::Reports::SearchAggregate's combine strategy -- reportable
# events are excluded from SearchEvent once they are folded into a rollup,
# so the two sources never double count.
class PublicServiceDemand
  WINDOW_DAYS = 30
  MINIMUM_RELEASABLE_SEARCHES = 3

  Result = Data.define(:searches, :released)

  def call(service_id:, city_code:)
    start_date = WINDOW_DAYS.days.ago.to_date
    start_at = start_date.in_time_zone

    raw = SearchEvent.reportable.where(service_id:, city_code:, created_at: start_at..).count
    rolled_up = SearchDailyRollup.where(service_id:, city_code:, report_date: start_date..).sum(:searches)
    total = raw + rolled_up

    Result.new(searches: total, released: total >= MINIMUM_RELEASABLE_SEARCHES)
  end
end
