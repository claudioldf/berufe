# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalSearchesController < BaseController
      # Public reads stay cacheable on purpose (see PublicProfessionalsController).
      # This operation is a POST that records a SearchEvent, so it is not
      # cacheable in practice either way.
      def create
        result = if structured_request?
          PublicProfessionalSearch.new.call_with_filters(
            service_id: params.require(:service_id),
            state_code: params.require(:state_code),
            city: params.require(:city),
            page: params[:page],
            per_page: params[:per_page]
          )
        else
          PublicSearchRateLimiter.new.check_and_increment!(ip_address: request.remote_ip)
          PublicProfessionalSearch.new.call(
            expression: params.require(:expression),
            page: params[:page],
            per_page: params[:per_page]
          )
        end
        result.professionals.load
        interaction = PublicSearchEventRecorder.new.call(
          criteria: result.criteria,
          result_count: result.total_count
        )
        render json: {
          data: PublicProfessionalSearchSerializer.new(result, interaction:).as_json,
          request_id: Current.request_id
        }
      rescue PublicProfessionalSearch::InvalidInput => error
        render_api_error(
          code: "validation_failed",
          message: "Revise os campos informados.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue PublicSearchRateLimiter::RateLimited => error
        response.set_header("Retry-After", error.retry_after.to_s)
        render_api_error(
          code: "public_search_rate_limited",
          message: "Muitas buscas em pouco tempo. Tente novamente em instantes.",
          status: :too_many_requests
        )
      rescue LlmSearchParser::ProviderRateLimited => error
        report_service_error(error)
        response.set_header("Retry-After", error.retry_after.to_s)
        render_api_error(
          code: "public_search_rate_limited",
          message: "Muitas buscas em pouco tempo. Tente novamente em instantes.",
          status: :too_many_requests
        )
      rescue LlmSearchParser::ProviderUnavailable => error
        report_service_error(error)
        render_api_error(
          code: "llm_search_unavailable",
          message: "Não conseguimos interpretar sua busca agora. Tente novamente.",
          status: :service_unavailable
        )
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Busca temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      def structured_request?
        %i[service_id state_code city].any? { |key| params.key?(key) }
      end
    end
  end
end
