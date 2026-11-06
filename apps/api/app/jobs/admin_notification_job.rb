# frozen_string_literal: true

# Fans an administrator-facing event out to one delivery job per active
# administrator, so a provider failure for one recipient never repeats the
# message to the others.
class AdminNotificationJob < ApplicationJob
  queue_as :default
  self.enqueue_after_transaction_commit = true

  def perform(event, subject_id, delivery_job: AdminNotificationDeliveryJob)
    raise ArgumentError, "unknown admin notification event: #{event}" unless
      AdminNotificationDeliveryJob::EVENTS.include?(event)

    UserAccount.where(role: "admin", status: "active").where.not(email: nil).pluck(:id).each do |admin_id|
      delivery_job.perform_later(event, subject_id, admin_id)
    end
  end
end
