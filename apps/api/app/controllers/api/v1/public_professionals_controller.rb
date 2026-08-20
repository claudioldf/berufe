# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalsController < BaseController
      # Public reads stay cacheable on purpose: the architecture reserves a
      # 60-second shared stale-while-revalidate cache as the remedy if the
      # public latency budget is missed, and `no-store` or `private` would
      # forbid the shared cache that remedy needs. Freshness is unchanged --
      # a cache must still revalidate on every request.
      SHARED_CACHE_CONTROL = "max-age=0, public, must-revalidate"

      after_action :allow_shared_cache, only: :show

      def show
        profile = PublicProfessionalProfileQuery.new.call(slug: params[:slug])
        professional = PublicProfessionalProfileSerializer.new(profile).as_json
        raise ActiveRecord::RecordNotFound unless professional

        token = PublicProfileInteractionIssuer.new.call(
          profile:,
          search_token: params[:interaction_token]
        )
        render json: {
          data: {
            professional:,
            interaction: {token:}
          },
          request_id: Current.request_id
        }
      rescue ActiveRecord::RecordNotFound
        raise
      rescue ActiveRecord::ActiveRecordError
        render_api_error(
          code: "service_unavailable",
          message: "Perfil temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      def allow_shared_cache
        return unless response.successful?

        response.set_header("Cache-Control", SHARED_CACHE_CONTROL)
      end
    end
  end
end
