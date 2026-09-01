# frozen_string_literal: true

class ProfessionalNotificationRouteResolver
  DASHBOARD_ROUTE = "/app/professional"
  PROFILE_ROUTE = "/app/professional/profile"
  STATIC_ROUTES = {
    "profile_moderation_hidden" => DASHBOARD_ROUTE,
    "profile_moderation_restored" => DASHBOARD_ROUTE,
    "verification_request_moderation_approved" => "#{PROFILE_ROUTE}?tab=verificacoes",
    "verification_request_moderation_rejected" => "#{PROFILE_ROUTE}?tab=verificacoes",
    "relationship_request_received" => "#{PROFILE_ROUTE}?tab=relacoes",
    "relationship_request_accepted" => "#{PROFILE_ROUTE}?tab=relacoes",
    "relationship_request_declined" => "#{PROFILE_ROUTE}?tab=relacoes"
  }.freeze
  QUOTE_TYPES = %w[quote_change_requested quote_declined].freeze
  SERVICE_JOB_TYPES = %w[service_completion_issue_reported].freeze

  def call(notification)
    type = notification.notification_type
    return STATIC_ROUTES.fetch(type) if STATIC_ROUTES.key?(type)
    return quote_approved_route(notification) if type == "quote_approved"
    return quote_route(notification.route_params.fetch("quote_id")) if type.in?(QUOTE_TYPES)
    return service_job_route(notification.route_params.fetch("service_job_id")) if type.in?(SERVICE_JOB_TYPES)
    return recommendation_route(notification) if type == "customer_recommendation_published"

    raise KeyError, "unknown professional notification type: #{type}"
  end

  private

  # Resolved at read time, not stored, so approving a quote before this
  # change shipped still routes correctly, and the stored route_params shape
  # (quote_id) never needs a migration.
  def quote_approved_route(notification)
    quote_id = notification.route_params.fetch("quote_id")
    service_job = ServiceJob.find_by(quote_id:)
    service_job ? service_job_route(service_job.id) : quote_route(quote_id)
  end

  def quote_route(quote_id)
    "/app/professional/quotes/new?#{Rack::Utils.build_query(quote: quote_id)}"
  end

  def service_job_route(service_job_id)
    "/app/professional/services/#{service_job_id}"
  end

  def recommendation_route(notification)
    slug = notification.recipient_user_account.professional_profile&.public_slug
    return PROFILE_ROUTE unless slug

    "/profissionais/#{slug}#customer-recommendations-title"
  end
end
