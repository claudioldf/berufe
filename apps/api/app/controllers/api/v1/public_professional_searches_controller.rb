# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalSearchesController < BaseController
      def create
        result = PublicProfessionalSearch.new.call(
          term: params.require(:service),
          neighborhood_code: params[:neighborhoodCode]
        )
        render json: {
          data: PublicProfessionalSearchSerializer.new(result).as_json,
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
