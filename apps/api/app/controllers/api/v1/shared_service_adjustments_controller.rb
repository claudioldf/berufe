# frozen_string_literal: true

module Api
  module V1
    class SharedServiceAdjustmentsController < BaseController
      before_action :protect_bearer_response

      def decide
        decision = params.require(:decision).permit(:kind, :revision, :terms_accepted, :message)
        result = SharedServiceAdjustmentDecisionRecorder.new.call(
          token: params[:token],
          adjustment_id: params[:adjustment_id],
          decision: decision[:kind],
          revision: decision[:revision],
          terms_accepted: decision[:terms_accepted],
          message: decision[:message]
        )
        render json: {
          data: SharedQuoteSerializer.new(quote: result.quote, professional: result.professional),
          request_id: Current.request_id
        }
      rescue SharedQuoteResolver::NotFound
        render_not_found
      rescue SharedServiceAdjustmentDecisionRecorder::Invalid => error
        render_api_error(
          code: "validation_failed",
          message: "Revise sua resposta ao ajuste.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue SharedServiceAdjustmentDecisionRecorder::Stale
        render_api_error(
          code: "service_adjustment_stale",
          message: "Este ajuste mudou. Atualize a página antes de responder.",
          status: :conflict
        )
      rescue SharedServiceAdjustmentDecisionRecorder::Unavailable
        render_api_error(
          code: "service_adjustment_transition_unavailable",
          message: "Esta ação não está mais disponível. Atualize a página.",
          status: :conflict
        )
      end

      private

      def protect_bearer_response
        response.set_header("Cache-Control", "private, no-store")
        response.set_header("Referrer-Policy", "no-referrer")
        response.set_header("X-Robots-Tag", "noindex, nofollow")
      end

      def render_not_found
        render_api_error(
          code: "not_found",
          message: "Ajuste não encontrado.",
          status: :not_found
        )
      end
    end
  end
end
