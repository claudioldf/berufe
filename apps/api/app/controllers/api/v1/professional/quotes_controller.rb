# frozen_string_literal: true

module Api
  module V1
    module Professional
      class QuotesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          profile = owned_profile!
          authorize Quote, :index?
          quotes = policy_scope(Quote)
            .where(professional: profile)
            .includes(:quote_items)
            .newest_first
          render json: {
            data: {quotes: quotes.map { |quote| ProfessionalQuoteSerializer.new(quote) }},
            request_id: Current.request_id
          }
        end

        def create
          profile = owned_profile!
          quote = profile.quotes.new
          authorize quote, :create?
          quote = ProfessionalQuoteWriter.new.call(
            profile:,
            attributes: quote_params.to_h.deep_symbolize_keys
          )
          render json: quote_response(quote),
            status: :created,
            location: "/api/v1/professional/quotes/#{quote.id}"
        rescue ProfessionalQuoteWriter::Invalid => error
          render_quote_errors(error)
        end

        def show
          quote = owned_quote!
          authorize quote, :show?
          render json: quote_response(quote)
        end

        def update
          quote = owned_quote!
          authorize quote, :update?
          quote = ProfessionalQuoteWriter.new.call(
            profile: quote.professional,
            quote:,
            attributes: quote_params.to_h.deep_symbolize_keys
          )
          render json: quote_response(quote)
        rescue ProfessionalQuoteWriter::Invalid => error
          render_quote_errors(error)
        end

        private

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end

        def owned_quote!
          policy_scope(Quote).find(params[:id])
        end

        def quote_params
          params.require(:quote).permit(
            :customer_name,
            :service_description,
            :discount_amount,
            :valid_until,
            :notes,
            items: %i[description quantity unit unit_price]
          )
        end

        def quote_response(quote)
          {
            data: {quote: ProfessionalQuoteSerializer.new(quote)},
            request_id: Current.request_id
          }
        end

        def render_quote_errors(error)
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados do orçamento.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end
      end
    end
  end
end
