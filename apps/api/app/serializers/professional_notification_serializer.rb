# frozen_string_literal: true

class ProfessionalNotificationSerializer
  def initialize(notification)
    @notification = notification
  end

  def as_json(*)
    {
      id: notification.id,
      notification_type: notification.notification_type,
      status: notification.status,
      title: notification.title,
      description: notification.description,
      route: notification.route,
      occurred_at: notification.occurred_at.iso8601,
      read_at: notification.read_at&.iso8601
    }
  end

  private

  attr_reader :notification
end
