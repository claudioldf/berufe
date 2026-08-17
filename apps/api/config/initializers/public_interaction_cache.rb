# frozen_string_literal: true

Rails.application.config.x.berufe.public_interaction_cache = ActiveSupport::Cache::MemoryStore.new(
  size: 8.megabytes
)
