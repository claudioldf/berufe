# frozen_string_literal: true

module Api
  module V1
    module Professional
      class RecommendationsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          authorize CustomerRecommendation, :index?
          recommendations = policy_scope(CustomerRecommendation)
            .publication_authorized
            .includes(service_job: :quote)
            .order(submitted_at: :desc, id: :desc)
          render json: {
            data: {
              recommendations: recommendations.map { |recommendation| ProfessionalRecommendationSerializer.new(recommendation).as_json }
            },
            request_id: Current.request_id
          }
        end

        def hide
          recommendation = owned_recommendation!
          authorize recommendation, :update?
          recommendation = ProfessionalRecommendationHider.new.call(
            recommendation:,
            reason: params.dig(:hide, :reason)
          )
          render json: recommendation_response(recommendation)
        rescue ProfessionalRecommendationHider::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise o motivo informado.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def unhide
          recommendation = owned_recommendation!
          authorize recommendation, :update?
          recommendation = ProfessionalRecommendationUnhider.new.call(recommendation:)
          render json: recommendation_response(recommendation)
        end

        private

        def owned_recommendation!
          policy_scope(CustomerRecommendation).publication_authorized.find(params[:id])
        end

        def recommendation_response(recommendation)
          {
            data: {recommendation: ProfessionalRecommendationSerializer.new(recommendation).as_json},
            request_id: Current.request_id
          }
        end
      end
    end
  end
end
