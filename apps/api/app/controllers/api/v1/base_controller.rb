# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      rescue_from ActiveRecord::RecordNotFound do
        render_api_error(code: "not_found", message: "Recurso não encontrado.", status: :not_found)
      end

      rescue_from Pundit::NotAuthorizedError do
        render_api_error(
          code: "authorization_denied",
          message: "Você não tem permissão para realizar esta ação.",
          status: :forbidden
        )
      end

      rescue_from ActionController::ParameterMissing do |exception|
        render_api_error(
          code: "validation_failed",
          message: "Revise os campos informados.",
          status: :unprocessable_entity,
          field_errors: {exception.param => ["é obrigatório"]}
        )
      end

      private

      def pundit_user
        Current.user_account
      end

      def authenticate_application_session!
        application_session = ApplicationSessionAuthenticator.new.call(
          token: request.cookies[ApplicationSession::COOKIE_NAME]
        )
        return render_authentication_required unless application_session

        Current.application_session = application_session
        Current.user_account = application_session.user_account
      end

      def verify_csrf_and_origin!
        return if valid_request_origin? && valid_csrf_token?

        render_api_error(
          code: "request_not_allowed",
          message: "Não foi possível validar esta solicitação.",
          status: :forbidden
        )
      end

      def render_authentication_required
        clear_application_session_cookie
        render_api_error(
          code: "authentication_required",
          message: "Entre novamente para continuar.",
          status: :unauthorized
        )
      end

      def clear_application_session_cookie
        response.delete_cookie(
          ApplicationSession::COOKIE_NAME,
          secure: true,
          httponly: true,
          same_site: :lax,
          path: "/"
        )
      end

      def valid_request_origin?
        request.headers["Origin"] == ENV.fetch("WEB_ORIGIN")
      end

      def valid_csrf_token?
        supplied_token = request.headers["X-CSRF-Token"].to_s
        return false if supplied_token.empty?

        supplied_digest = SessionSecurityDigest.call(purpose: "csrf_token", value: supplied_token)
        ActiveSupport::SecurityUtils.secure_compare(
          supplied_digest,
          Current.application_session.csrf_token_digest
        )
      end

      def prevent_caching
        response.set_header("Cache-Control", "no-store")
      end

      def render_api_error(code:, message:, status:, field_errors: nil)
        error = {code:, message:, request_id: Current.request_id}
        error[:field_errors] = field_errors if field_errors.present?
        render json: {error:}, status:
      end
    end
  end
end
