# frozen_string_literal: true

module Api
  module V1
    module Professional
      class PortfolioItemsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def create
          profile = owned_profile!
          item = PortfolioItemCreator.new.call(
            profile:,
            attributes: portfolio_item_params.to_h.symbolize_keys
          )
          render json: workspace_response(profile), status: :created,
            location: "/api/v1/professional/portfolio-items/#{item.id}"
        rescue PortfolioItemCreator::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados do trabalho.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def update
          profile = owned_profile!
          item = profile.portfolio_items.active.find(params[:id])
          PortfolioItemUpdater.new.call(
            profile:,
            item:,
            attributes: portfolio_item_params.to_h.symbolize_keys
          )
          render json: workspace_response(profile)
        rescue PortfolioItemUpdater::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados do trabalho.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def destroy
          profile = owned_profile!
          item = profile.portfolio_items.active.find(params[:id])
          PortfolioItemDeleter.new.call(item:)
          render json: workspace_response(profile)
        end

        private

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end

        def portfolio_item_params
          params.require(:portfolio_item).permit(
            :media_upload_id,
            :service_id,
            :title,
            :description
          )
        end

        def workspace_response(profile)
          {
            data: ProfessionalWorkspaceSerializer.new(profile.reload),
            request_id: Current.request_id
          }
        end
      end
    end
  end
end
