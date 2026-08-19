# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ReportsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!
        before_action :require_password_admin_authentication!
        before_action -> { authorize :admin_report, :show? }

        def growth
          period = params[:period].presence || "since_launch"
          report = ::Admin::Reports::GrowthReport.new(period:).call
          Rails.logger.info(
            "admin_growth_report_access admin_user_id=#{Current.user_account.id} " \
              "request_id=#{Current.request_id} period=#{period} occurred_at=#{Time.current.iso8601}"
          )
          render json: {data: report, request_id: Current.request_id}
        rescue ::Admin::Reports::Period::Invalid
          render_api_error(
            code: "validation_failed",
            message: "Revise o período do relatório.",
            status: :unprocessable_entity,
            field_errors: {period: ["use um dos valores: #{::Admin::Reports::Period::KEYS.join(", ")}"]}
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
