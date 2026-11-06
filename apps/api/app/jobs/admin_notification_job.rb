# frozen_string_literal: true

# Fans an administrator-facing event out to one delivery job per address in
# ADMIN_NOTIFICATION_EMAILS, so a provider failure for one recipient never
# repeats the message to the others.
class AdminNotificationJob < ApplicationJob
  queue_as :default
  self.enqueue_after_transaction_commit = true

  def perform(event, subject_id, delivery_job: AdminNotificationDeliveryJob)
    raise ArgumentError, "unknown admin notification event: #{event}" unless
      AdminNotificationDeliveryJob::EVENTS.include?(event)

    recipients.each { |email| delivery_job.perform_later(event, subject_id, email) }
  end

  private

  def recipients
    Rails.application.config.x.berufe.environment.admin_notification_emails
  end
end
