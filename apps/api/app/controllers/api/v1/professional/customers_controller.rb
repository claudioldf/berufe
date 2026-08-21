# frozen_string_literal: true

module Api
  module V1
    module Professional
      class CustomersController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          profile = owned_profile!
          result = ProfessionalCustomerIndexQuery.new.call(
            scope: profile.customers,
            search: params[:search],
            page: params[:page],
            per_page: params[:per_page]
          )
          render json: {
            data: {
              customers: result.customers.map do |customer|
                ProfessionalCustomerSerializer.new(
                  customer,
                  quote_count: customer[:quote_count],
                  last_quote_at: customer[:last_quote_at]
                ).as_json
              end,
              meta: result.meta
            },
            request_id: Current.request_id
          }
        rescue ProfessionalCustomerIndexQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os filtros dos clientes.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def show
          customer = owned_customer!
          render json: customer_response(customer)
        end

        def update
          customer = ProfessionalCustomerUpdater.new.call(
            customer: owned_customer!,
            attributes: customer_params
          )
          render json: customer_response(customer)
        rescue ProfessionalCustomerUpdater::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados do cliente.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        private

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end

        def owned_customer!
          owned_profile!.customers.find(params[:id])
        end

        def customer_params
          params.require(:customer).permit(:name, :whatsapp_e164, :email)
        end

        def customer_response(customer)
          {
            data: {customer: ProfessionalCustomerSerializer.new(customer).as_json},
            request_id: Current.request_id
          }
        end
      end
    end
  end
end
