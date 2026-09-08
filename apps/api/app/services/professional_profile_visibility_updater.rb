# frozen_string_literal: true

class ProfessionalProfileVisibilityUpdater
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional profile visibility")
    end
  end

  class Unavailable < StandardError; end

  def call(profile:, visibility:)
    raise Unavailable unless profile.profile_status == "published"

    normalized_visibility = visibility.to_s
    unless normalized_visibility.in?(ProfessionalProfile::PUBLIC_VISIBILITIES)
      raise Invalid, {visibility: ["selecione uma opção de visibilidade válida"]}
    end

    profile.update!(public_visibility: normalized_visibility)
    profile
  end
end
