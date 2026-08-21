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
          result = ProfessionalQuoteIndexQuery.new.call(
            scope: policy_scope(Quote).where(professional: profile),
            search: params[:search],
            status: params[:status],
            scheduled_on: params[:scheduled_on],
            sort: params[:sort],
            direction: params[:direction],
            page: params[:page],
            per_page: params[:per_page]
          )
          quotes = result.quotes
            .includes(
              :quote_items,
              :customer,
              :quote_change_requests,
              service_job: :customer_recommendation_request
            )
          render json: {
            data: {
              quotes: quotes.map { |quote| ProfessionalQuoteSerializer.new(quote) },
              meta: result.meta
            },
            request_id: Current.request_id
          }
        rescue ProfessionalQuoteIndexQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os filtros dos orçamentos.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
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
        rescue ProfessionalQuoteWriter::Locked
          render_quote_locked
        rescue ProfessionalQuoteWriter::Stale
          render_quote_stale
        end

        def share
          quote = owned_quote!
          authorize quote, :share?
          result = ProfessionalQuoteSharer.new.call(
            quote:,
            method: params.dig(:share, :method)
          )
          render json: {
            data: {
              quote: ProfessionalQuoteSerializer.new(result.quote),
              share_url: result.share_url,
              whatsapp_url: result.whatsapp_url
            },
            request_id: Current.request_id
          }
        rescue ProfessionalQuoteSharer::Unavailable
          render_api_error(
            code: "quote_sharing_unavailable",
            message: "Publique seu perfil para compartilhar este orçamento.",
            status: :unprocessable_entity
          )
        rescue ProfessionalQuoteSharer::InvalidMethod
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados de compartilhamento.",
            status: :unprocessable_entity,
            field_errors: {method: ["não é válido"]}
          )
        end

        def revoke_share
          quote = owned_quote!
          authorize quote, :share?
          quote = ProfessionalQuoteRevoker.new.call(quote:)
          render json: quote_response(quote)
        rescue ProfessionalQuoteRevoker::NotShared
          render_api_error(
            code: "quote_not_shared",
            message: "Este orçamento não possui um link ativo.",
            status: :unprocessable_entity
          )
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
            :service_description,
            :service_address,
            :scheduled_on,
            :discount_amount,
            :valid_until,
            :notes,
            :revision,
            customer: %i[id name whatsapp_e164 email],
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

        def render_quote_locked
          render_api_error(
            code: "quote_locked",
            message: "Um orçamento aprovado não pode mais ser alterado.",
            status: :conflict
          )
        end

        def render_quote_stale
          render_api_error(
            code: "quote_stale",
            message: "Este orçamento mudou. Atualize a página antes de continuar.",
            status: :conflict
          )
        end
      end
    end
  end
end
