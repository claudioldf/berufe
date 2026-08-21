# frozen_string_literal: true

module Api
  module V1
    module Professional
      class CustomerCandidatesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          professional = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless professional

          authorize professional, :update?
          customers = ProfessionalCustomerCandidateQuery.new.call(
            professional:,
            query: params[:query]
          )
          render json: {
            data: {
              customers: customers.map do |customer|
                ProfessionalCustomerCandidateSerializer.new(customer).as_json
              end
            },
            request_id: Current.request_id
          }
        rescue ProfessionalCustomerCandidateQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a busca informada.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end
      end
    end
  end
end
