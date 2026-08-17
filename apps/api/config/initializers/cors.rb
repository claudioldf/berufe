# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("WEB_ORIGIN")

    resource "/api/v1/*",
      headers: %w[Content-Type X-Request-Id],
      expose: %w[Retry-After X-Request-Id],
      methods: %i[get post put patch delete options head],
      credentials: true,
      max_age: 600
  end
end
