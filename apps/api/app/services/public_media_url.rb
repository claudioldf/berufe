# frozen_string_literal: true

# Public clients always use the Rails route. It rechecks current eligibility so
# a moderation takedown cannot be bypassed with a long-lived object URL.
module PublicMediaUrl
  def self.call(rails_path:, environment: ENV)
    "#{environment.fetch("API_PUBLIC_URL").delete_suffix("/")}#{rails_path}"
  end
end
