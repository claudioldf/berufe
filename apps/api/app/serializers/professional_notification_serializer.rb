# frozen_string_literal: true

class ProfessionalNotificationSerializer
  def initialize(notification, route_resolver: ProfessionalNotificationRouteResolver.new)
    @notification = notification
    @route_resolver = route_resolver
  end

  def as_json(*)
    {
      id: notification.id,
      notification_type: notification.notification_type,
      status: notification.status,
      title: notification.title,
      description: notification.description,
      route: route_resolver.call(notification),
      occurred_at: notification.occurred_at.iso8601,
      read_at: notification.read_at&.iso8601
    }
  end

  private

  attr_reader :notification, :route_resolver
end
