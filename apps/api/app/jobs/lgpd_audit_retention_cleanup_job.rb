# frozen_string_literal: true

class LgpdAuditRetentionCleanupJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current)
    LegalRetentionRecord.where(retained_until: ..now).delete_all
    DataErasureRequest.where(retained_until: ..now, status: "completed").delete_all
  end
end
