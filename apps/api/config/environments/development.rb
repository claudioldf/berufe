require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Permit Nuxt's server-side requests over the Compose service network.
  config.hosts << "api"

  # Enable server timing.
  config.server_timing = true

  # Enable/disable Action Controller caching. By default Action Controller caching is disabled.
  # Run rails dev:cache to toggle Action Controller caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.public_file_server.headers = {"cache-control" => "public, max-age=#{2.days.to_i}"}
  else
    config.action_controller.perform_caching = false
  end

  # Change to :null_store to avoid any caching.
  config.cache_store = :memory_store

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Append comments with runtime information tags to SQL queries in logs.
  config.active_record.query_log_tags_enabled = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Highlight code that triggered redirect in logs.
  config.action_dispatch.verbose_redirect_logs = true

  # MailCatcher (compose.yaml) traps outgoing mail at http://localhost:1080.
  # Deliberately separate from the production-shaped SMTP_* variables (whose
  # .env.example defaults, e.g. port 587, do not describe MailCatcher).
  # Override MAILER_SMTP_HOST/PORT for a host-run `bin/rails server` pointed
  # at a locally installed MailCatcher instead of the Compose one — the
  # Compose container also publishes 1025 to the host, so localhost works.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("MAILER_SMTP_HOST", "mailcatcher"),
    port: Integer(ENV.fetch("MAILER_SMTP_PORT", "1025")),
    enable_starttls_auto: false
  }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true
end
