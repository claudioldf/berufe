# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalWhatsappController < BaseController
      before_action :prevent_caching

      def show
        profile = ProfessionalProfile.publicly_viewable.find(params[:id])
        interaction = PublicWhatsappInteractionResolver.new.call(
          profile:,
          source: params[:source],
          token: params[:interaction_token]
        )
        redirect_url = PublicWhatsappUrl.call(
          phone_e164: profile.published_revision.whatsapp_e164,
          service_name: interaction.service_name
        )
        if PublicInteractionUserAgent.countable?(request.user_agent)
          PublicWhatsappHandoffRecorder.new.call(profile:, interaction:)
        end

        redirect_to redirect_url, allow_other_host: true, status: :found
      rescue PublicWhatsappInteractionResolver::InvalidInteraction
        render_api_error(
          code: "validation_failed",
          message: "Interação inválida ou expirada.",
          status: :unprocessable_entity,
          field_errors: {interaction_token: ["é inválido ou expirou"]}
        )
      rescue PublicWhatsappUrl::InvalidContact
        raise ActiveRecord::RecordNotFound
      rescue ActiveRecord::RecordNotFound
        raise
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Perfil temporariamente indisponível.",
          status: :service_unavailable
        )
      end
    end
  end
end
