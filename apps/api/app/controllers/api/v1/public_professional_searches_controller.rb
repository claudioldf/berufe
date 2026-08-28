# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalSearchesController < BaseController
      # Public reads stay cacheable on purpose (see PublicProfessionalsController).
      # This operation is a POST that records a SearchEvent, so it is not
      # cacheable in practice either way.
      def create
        audit_event = nil
        page, per_page = PublicProfessionalSearch.normalize_pagination(
          page: params[:page],
          per_page: params[:per_page]
        )
        search = PublicProfessionalSearch.new
        result = if structured_request?
          search.call_with_filters(
            service_id: params.require(:service_id),
            city_code: params.require(:city_code),
            page:,
            per_page:
          )
        else
          expression = params.require(:expression)
          ip_address = visitor_ip_resolver.call(request)
          default_location = expression_default_location(ip_address:)
          audit_event = audit_recorder.start(expression:, city_code: default_location.city_code) if page == 1
          PublicSearchRateLimiter.new.check_and_increment!(ip_address:)
          search.call(
            expression:,
            default_location:,
            page:,
            per_page:,
            audit_event:
          )
        end
        result.professionals.load
        interaction = if page == 1
          PublicSearchEventRecorder.new.call(
            criteria: result.criteria,
            result_count: result.total_count,
            subject: search_deduplication_subject,
            query: search_deduplication_query(result.criteria),
            event: audit_event
          )
        end
        render json: {
          data: PublicProfessionalSearchSerializer.new(result, interaction:).as_json,
          request_id: Current.request_id
        }
      rescue LlmSearchParser::InvalidExpression
        render_api_error(
          code: "validation_failed",
          message: "Revise os campos informados.",
          status: :unprocessable_entity,
          field_errors: {
            expression: ["é obrigatória e deve ter no máximo #{LlmSearchParser::MAXIMUM_EXPRESSION_LENGTH} caracteres"]
          }
        )
      rescue PublicProfessionalSearch::InvalidInput => error
        record_audit_failure(audit_event, status: "response_rejected")
        render_api_error(
          code: "validation_failed",
          message: "Revise os campos informados.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue PublicSearchRateLimiter::RateLimited => error
        record_audit_failure(audit_event, status: "application_rate_limited")
        response.set_header("Retry-After", error.retry_after.to_s)
        render_api_error(
          code: "public_search_rate_limited",
          message: "Muitas buscas em pouco tempo. Tente novamente em instantes.",
          status: :too_many_requests
        )
      rescue LlmSearchParser::ProviderRateLimited => error
        record_audit_failure(audit_event, status: "provider_rate_limited")
        report_service_error(error)
        response.set_header("Retry-After", error.retry_after.to_s)
        render_api_error(
          code: "public_search_rate_limited",
          message: "Muitas buscas em pouco tempo. Tente novamente em instantes.",
          status: :too_many_requests
        )
      rescue LlmSearchParser::ProviderUnavailable => error
        record_audit_failure(audit_event, status: "provider_unavailable")
        report_service_error(error)
        render_api_error(
          code: "llm_search_unavailable",
          message: "Não conseguimos interpretar sua busca agora. Tente novamente.",
          status: :service_unavailable
        )
      rescue ActiveRecord::ActiveRecordError => error
        record_audit_failure(audit_event, status: "search_failed")
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Busca temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      def audit_recorder
        @audit_recorder ||= PublicSearchAuditRecorder.new
      end

      def visitor_ip_resolver
        @visitor_ip_resolver ||= VisitorIpResolver.new
      end

      def expression_default_location(ip_address:)
        if params[:default_location].present?
          city_code = params.require(:default_location).permit(:city_code).fetch(:city_code)
          location = SupportedSearchLocations.new.find_by_code(city_code:)
          return location if location

          raise PublicProfessionalSearch::InvalidInput,
            {default_location: ["selecione uma cidade disponível"]}
        end

        PublicSearchLocationResolver.new.call(ip_address:).location
      end

      def record_audit_failure(event, status:)
        return unless event&.audit_status == "processing"

        audit_recorder.record_failure(event:, status:)
      end

      def structured_request?
        %i[service_id city_code].any? { |key| params.key?(key) }
      end

      def search_deduplication_subject
        session_token = request.cookies[ApplicationSession::COOKIE_NAME].presence
        return "session\0#{session_token}" if session_token

        "ip\0#{request.remote_ip}"
      end

      def search_deduplication_query(criteria)
        if structured_request?
          [
            "structured",
            params[:service_id].to_s.downcase,
            params[:city_code].to_s
          ].join("\0")
        else
          [
            "expression",
            PublicSearchText.normalize(params[:expression]),
            criteria.locations.first.city_code
          ].join("\0")
        end
      end
    end
  end
end
