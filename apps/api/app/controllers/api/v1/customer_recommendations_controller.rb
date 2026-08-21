# frozen_string_literal: true

module Api
  module V1
    class CustomerRecommendationsController < BaseController
      before_action :protect_bearer_response

      def resolve
        request_record = CustomerRecommendationResolver.new.call(token: params[:token])
        render json: {
          data: {recommendation_request: CustomerRecommendationRequestSerializer.new(request_record)},
          request_id: Current.request_id
        }
      rescue CustomerRecommendationResolver::NotFound
        render_not_found
      end

      def create
        recommendation = CustomerRecommendationSubmitter.new.call(
          token: params[:token],
          attributes: recommendation_params.to_h.deep_symbolize_keys
        )
        render json: {
          data: {recommendation: CustomerRecommendationSerializer.new(recommendation)},
          request_id: Current.request_id
        }, status: :created
      rescue CustomerRecommendationResolver::NotFound, CustomerRecommendationSubmitter::Unavailable
        render_not_found
      rescue CustomerRecommendationSubmitter::Invalid => error
        render_api_error(
          code: "validation_failed",
          message: "Revise sua recomendação.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      end

      private

      def recommendation_params
        params.require(:recommendation).permit(
          :display_name,
          :recommendation_text,
          :service_confirmed,
          :publication_consent
        )
      end

      def protect_bearer_response
        response.set_header("Cache-Control", "private, no-store")
        response.set_header("Referrer-Policy", "no-referrer")
        response.set_header("X-Robots-Tag", "noindex, nofollow")
      end

      def render_not_found
        render_api_error(
          code: "not_found",
          message: "Este convite não está disponível.",
          status: :not_found
        )
      end
    end
  end
end
