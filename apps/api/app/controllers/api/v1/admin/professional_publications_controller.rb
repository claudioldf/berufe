# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProfessionalPublicationsController < ProfessionalsBaseController
        def create
          ::Admin::ProfessionalPublicationDecision.new.call(
            professional_profile_id: params[:id],
            published: publication_params[:published],
            reason: publication_params[:reason]
          )
          result = ::Admin::ProfessionalIndexQuery.new.call(**directory_query_params)
          render json: {
            data: AdminProfessionalSerializer.new(result).as_json,
            request_id: Current.request_id
          }
        rescue ::Admin::ProfessionalPublicationDecision::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a decisão de publicação informada.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        rescue ::Admin::ProfessionalPublicationDecision::Conflict
          render_api_error(
            code: "professional_publication_conflict",
            message: "O perfil mudou. Atualize a lista e tente novamente.",
            status: :conflict
          )
        end

        private

        def publication_params
          params.require(:publication).permit(:published, :reason)
        end
      end
    end
  end
end
