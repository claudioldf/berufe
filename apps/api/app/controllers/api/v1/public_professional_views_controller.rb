# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalViewsController < BaseController
      class InvalidInteraction < StandardError; end

      before_action :prevent_caching

      def create
        profile = ProfessionalProfile.publicly_viewable.find(params[:id])
        interaction = PublicProfileInteractionToken.new.verify(params.require(:interaction_token))
        raise InvalidInteraction unless interaction&.professional_id == profile.id

        PublicProfileViewRecorder.new.call(profile:, interaction:)
        head :no_content
      rescue InvalidInteraction
        render_api_error(
          code: "validation_failed",
          message: "Interação inválida ou expirada.",
          status: :unprocessable_entity,
          field_errors: {interaction_token: ["é inválido ou expirou"]}
        )
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
