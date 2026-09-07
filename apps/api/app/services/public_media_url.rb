# frozen_string_literal: true

# Public clients always use a Rails route. It rechecks current eligibility so a
# whole-profile takedown cannot be bypassed with a long-lived object URL —
# bounded to a few minutes rather than instant for :media, which sits behind a
# short-TTL Cloudflare cache (see docs/PRODUCTION_DEPLOYMENT.md).
module PublicMediaUrl
  HOST_ENV_KEYS = {
    api: "API_PUBLIC_URL",
    media: "MEDIA_PUBLIC_URL"
  }.freeze

  def self.call(rails_path:, host: :api, environment: ENV)
    env_key = HOST_ENV_KEYS.fetch(host)
    "#{environment.fetch(env_key).delete_suffix("/")}#{rails_path}"
  end
end
