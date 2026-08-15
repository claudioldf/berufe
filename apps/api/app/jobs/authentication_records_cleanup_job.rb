# frozen_string_literal: true

class AuthenticationRecordsCleanupJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current)
    OtpRequestCounter.where(expires_at: ..now).delete_all
    OtpChallenge.where(expires_at: ..now).delete_all
    ApplicationSession
      .where("idle_expires_at <= :now OR absolute_expires_at <= :now", now:)
      .delete_all
  end
end
