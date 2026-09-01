require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = {"cache-control" => "public, max-age=#{1.year.to_i}"}

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Railway probes the container over its private HTTP network before switching
  # public TLS traffic to a new deployment.
  config.ssl_options = {redirect: {exclude: ->(request) { request.path == "/up" }}}

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  # Deployed environments (staging/integration/production) run on Railway,
  # which blocks outbound SMTP below its Pro plan — a connection to
  # smtp.resend.com:587 times out (Net::OpenTimeout) rather than being
  # refused. MAIL_ADAPTER=resend routes mail through Resend's HTTP API
  # instead (see lib/berufe/resend_mail_client.rb); MAIL_ADAPTER=smtp is kept
  # for rollback and for preview, which does not require either adapter's
  # variables and falls back to these unset-safe defaults.
  if ENV.fetch("MAIL_ADAPTER", "smtp") == "resend"
    # Registered here, directly on the class, rather than through
    # config.action_mailer.resend_settings — the ActionMailer railtie's
    # "action_mailer.set_configs" initializer applies config.action_mailer.*
    # before any config/initializers/*.rb runs, so a not-yet-registered
    # `:resend` delivery method would leave no resend_settings= to call.
    require Rails.root.join("lib/berufe/mail_delivery")
    require Rails.root.join("lib/berufe/resend_mail_client")
    ActionMailer::Base.add_delivery_method(
      :resend,
      Berufe::ResendMailClient,
      api_key: ENV.fetch("RESEND_API_KEY"),
      request_timeout: ENV.fetch("RESEND_REQUEST_TIMEOUT_SECONDS", "10").to_f
      # No logger: this settings hash is frozen at boot, before Rails.logger
      # exists — ResendMailClient falls back to Rails.logger lazily instead.
    )
    config.action_mailer.delivery_method = :resend
  else
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS", "localhost"),
      port: ENV.fetch("SMTP_PORT", "587").to_i,
      domain: ENV.fetch("SMTP_DOMAIN", "berufe.com.br"),
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain"),
      enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true",
      open_timeout: ENV.fetch("SMTP_OPEN_TIMEOUT_SECONDS", "10").to_i,
      read_timeout: ENV.fetch("SMTP_READ_TIMEOUT_SECONDS", "10").to_i
    }
  end

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
