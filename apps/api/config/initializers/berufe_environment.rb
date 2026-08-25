# frozen_string_literal: true

require Rails.root.join("lib/berufe/environment")

Rails.application.config.x.berufe.environment = Berufe::Environment.load!(
  rails_environment: Rails.env.to_s
)
Rails.application.config.x.berufe.reporting = ActiveSupport::OrderedOptions.new
Rails.application.config.x.berufe.reporting.product_launch_date =
  Rails.application.config.x.berufe.environment.product_launch_date
Rails.application.config.x.berufe.reporting.raw_search_retention_days = 90
Rails.application.config.x.berufe.reporting.llm_search_audit_retention_days = 7
Rails.application.config.x.berufe.reporting.aggregate_retention_days = 730
Rails.application.config.x.berufe.reporting.founding_target_minimum = 30
Rails.application.config.x.berufe.reporting.founding_target_maximum = 50
Rails.application.config.x.berufe.reporting.moderation_oldest_pending_target_hours = 24
