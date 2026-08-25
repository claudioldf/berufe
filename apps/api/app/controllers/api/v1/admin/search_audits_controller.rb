# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SearchAuditsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!
        before_action :require_password_admin_authentication!
        before_action -> { authorize :admin_search_audit, :index? }

        def index
          result = ::Admin::SearchAuditIndexQuery.new.call(
            page: params[:page],
            per_page: params[:per_page]
          )
          Rails.logger.info(
            "admin_search_audit_access admin_user_id=#{Current.user_account.id} " \
              "request_id=#{Current.request_id} page=#{result.page} occurred_at=#{Time.current.iso8601}"
          )
          render json: {
            data: AdminSearchAuditSerializer.new(result).as_json,
            request_id: Current.request_id
          }
        rescue ::Admin::SearchAuditIndexQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a paginação da auditoria.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        private

        def require_password_admin_authentication!
          return if performed? || !Current.user_account&.admin?
          return if Current.application_session.authentication_method == "password"

          render_authentication_required
        end
      end
    end
  end
end
