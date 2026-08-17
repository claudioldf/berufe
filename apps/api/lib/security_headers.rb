# frozen_string_literal: true

class SecurityHeaders
  HEADERS = {
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "DENY",
    "Referrer-Policy" => "no-referrer"
  }.freeze

  def initialize(application)
    @application = application
  end

  def call(environment)
    status, headers, body = @application.call(environment)
    HEADERS.each { |name, value| headers[name] = value }
    [status, headers, body]
  end
end
