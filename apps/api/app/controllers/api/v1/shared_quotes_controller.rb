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
    end
  end
end
