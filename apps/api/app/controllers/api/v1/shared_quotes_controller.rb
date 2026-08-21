# frozen_string_literal: true

module Api
  module V1
    class SharedQuotesController < BaseController
      before_action :protect_bearer_response

      def resolve
        result = SharedQuoteResolver.new.call(token: params[:token])
        render json: {
          data: SharedQuoteSerializer.new(
            quote: result.quote,
            professional: result.professional
          ),
          request_id: Current.request_id
        }
      rescue SharedQuoteResolver::NotFound
        render_shared_quote_not_found
      rescue ActiveRecord::ActiveRecordError
        render_api_error(
          code: "service_unavailable",
          message: "Orçamento temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      def decide
        decision = params.require(:decision).permit(:kind, :revision, :terms_accepted, :message)
        result = SharedQuoteDecisionRecorder.new.call(
          token: params[:token],
          decision: decision[:kind],
          revision: decision[:revision],
          terms_accepted: decision[:terms_accepted],
          message: decision[:message]
        )
        resolved = result[:resolved]
        render json: {
          data: SharedQuoteSerializer.new(
            quote: resolved.quote,
            professional: resolved.professional
          ),
          request_id: Current.request_id
        }
      rescue SharedQuoteResolver::NotFound
        render_shared_quote_not_found
      rescue SharedQuoteDecisionRecorder::Invalid => error
        render_api_error(
          code: "validation_failed",
          message: "Revise sua resposta.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue SharedQuoteDecisionRecorder::Stale
        render_api_error(
          code: "quote_stale",
          message: "Este orçamento mudou. Atualize a página antes de responder.",
          status: :conflict
        )
      rescue SharedQuoteDecisionRecorder::Expired
        render_api_error(
          code: "quote_expired",
          message: "A validade deste orçamento terminou.",
          status: :gone
        )
      rescue SharedQuoteDecisionRecorder::Unavailable
        render_transition_unavailable
      end

      def complete
        completion = params.require(:completion).permit(:kind, :message)
        result = SharedQuoteCompletionResponder.new.call(
          token: params[:token],
          response: completion[:kind],
          message: completion[:message]
        )
        resolved = result.resolved
        render json: {
          data: SharedQuoteSerializer.new(
            quote: resolved.quote,
            professional: resolved.professional
          ),
          request_id: Current.request_id
        }
      rescue SharedQuoteResolver::NotFound
        render_shared_quote_not_found
      rescue SharedQuoteCompletionResponder::Invalid => error
        render_api_error(
          code: "validation_failed",
          message: "Revise sua resposta.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue SharedQuoteCompletionResponder::Unavailable
        render_transition_unavailable
      end

      private

      def protect_bearer_response
        response.set_header("Cache-Control", "private, no-store")
        response.set_header("Referrer-Policy", "no-referrer")
        response.set_header("X-Robots-Tag", "noindex, nofollow")
      end

      def render_shared_quote_not_found
        render_api_error(
          code: "not_found",
          message: "Orçamento não encontrado.",
          status: :not_found
        )
      end

      def render_transition_unavailable
        render_api_error(
          code: "quote_transition_unavailable",
          message: "Esta ação não está mais disponível.",
          status: :conflict
        )
      end
    end
  end
end
