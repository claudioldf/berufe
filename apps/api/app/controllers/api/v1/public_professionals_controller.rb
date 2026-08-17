# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalsController < BaseController
      before_action :prevent_caching

      def show
        profile = PublicProfessionalProfileQuery.new.call(slug: params[:slug])
        professional = PublicProfessionalProfileSerializer.new(profile).as_json
        raise ActiveRecord::RecordNotFound unless professional

        token = PublicProfileInteractionIssuer.new.call(
          profile:,
          search_token: params[:interactionToken]
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
    end
  end
end
