# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalSearchesController < BaseController
      # Public reads stay cacheable on purpose (see PublicProfessionalsController).
      # This operation is a POST that records a SearchEvent, so it is not
      # cacheable in practice either way.
      def create
        term = params.require(:service)
        result = PublicProfessionalSearch.new.call(
          term:,
          neighborhood_code: params[:neighborhood_code],
          page: params[:page],
          per_page: params[:per_page]
        )
        result.professionals.load
        interaction = PublicSearchEventRecorder.new.call(
          raw_term: term,
          normalized_term: result.normalized_term,
          service: result.service,
          neighborhood: result.neighborhood,
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
      rescue ActiveRecord::ActiveRecordError
        render_api_error(
          code: "service_unavailable",
          message: "Busca temporariamente indisponível.",
          status: :service_unavailable
        )
      end
    end
  end
end
