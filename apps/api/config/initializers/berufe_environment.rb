# frozen_string_literal: true

require Rails.root.join("lib/berufe/environment")

Rails.application.config.x.berufe.environment = Berufe::Environment.load!(
  rails_environment: Rails.env.to_s
)
