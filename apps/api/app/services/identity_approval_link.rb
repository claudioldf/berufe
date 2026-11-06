# frozen_string_literal: true

module IdentityApprovalLink
  def self.profile_url(profile)
    "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/profissionais/#{profile.public_slug}"
  end
end
