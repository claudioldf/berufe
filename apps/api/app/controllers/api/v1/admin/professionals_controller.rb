# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProfessionalsController < ProfessionalsBaseController
        def index
          result = ::Admin::ProfessionalIndexQuery.new.call(**directory_query_params)
          Rails.logger.info(
            "admin_professional_directory_access admin_user_id=#{Current.user_account.id} " \
              "request_id=#{Current.request_id} page=#{result.page} occurred_at=#{Time.current.iso8601}"
          )
          render json: {
            data: AdminProfessionalSerializer.new(result).as_json,
            request_id: Current.request_id
          }
        rescue ::Admin::ProfessionalIndexQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os filtros ou a paginação da lista de profissionais.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end
      end
    end
  end
end
