# frozen_string_literal: true

class CustomerRecommendationRetentionCleanupJob < ApplicationJob
  queue_as :default

  RETENTION_PERIOD = 30.days

  def perform(now: Time.current)
    CustomerRecommendationRequest.where(status: "open", expires_at: ..now)
      .update_all(status: "expired", token_ciphertext: nil, updated_at: now)

    CustomerRecommendationRequest
      .where(status: %w[completed expired])
      .where("COALESCE(completed_at, expires_at) <= ?", now - RETENTION_PERIOD)
      .delete_all
  end
end
