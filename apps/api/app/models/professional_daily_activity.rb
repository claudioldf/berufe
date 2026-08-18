# frozen_string_literal: true

class ProfessionalDailyActivity < ApplicationRecord
  PRODUCT_TIME_ZONE = "America/Sao_Paulo"
  COUNTERS = %i[
    profile_updates
    evidence_creations
    relationship_interactions
    quotes_created
  ].freeze

  belongs_to :professional, class_name: "ProfessionalProfile", inverse_of: :daily_activities

  validates :activity_date, presence: true, uniqueness: {scope: :professional_id}
  validates(*COUNTERS, numericality: {only_integer: true, greater_than_or_equal_to: 0})

  def self.increment!(professional_id:, counter:, occurred_at: Time.current)
    counter = counter.to_sym
    raise KeyError, "unknown professional activity counter" unless counter.in?(COUNTERS)

    activity_date = occurred_at.in_time_zone(PRODUCT_TIME_ZONE).to_date
    insert_all(
      [{professional_id:, activity_date:}],
      unique_by: :idx_professional_daily_activities_professional_date
    )
    increment_counter!(where(professional_id:, activity_date:), counter)
    find_by!(professional_id:, activity_date:)
  end

  def self.increment_counter!(relation, counter)
    case counter
    when :profile_updates
      relation.update_all("profile_updates = profile_updates + 1, updated_at = CURRENT_TIMESTAMP")
    when :evidence_creations
      relation.update_all("evidence_creations = evidence_creations + 1, updated_at = CURRENT_TIMESTAMP")
    when :relationship_interactions
      relation.update_all("relationship_interactions = relationship_interactions + 1, updated_at = CURRENT_TIMESTAMP")
    when :quotes_created
      relation.update_all("quotes_created = quotes_created + 1, updated_at = CURRENT_TIMESTAMP")
    end
  end
  private_class_method :increment_counter!
end
