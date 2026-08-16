# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SessionsController < BaseController
        before_action :prevent_caching
        before_action :verify_request_origin!

        def create
          result = AdminPasswordAuthenticator.new.call(
            email: params[:email],
            password: params[:password],
            ip_address: request.remote_ip
          )
          set_application_session_cookie(session: result.session, token: result.session_token)

          render json: {
            data: {status: "authenticated"},
            request_id: Current.request_id
          }
        rescue AdminPasswordAuthenticator::Invalid
          render_invalid_credentials
        rescue AdminLoginRateLimiter::RateLimited => exception
          response.set_header("Retry-After", exception.retry_after.to_s)
          render_api_error(
            code: "login_rate_limited",
            message: "Muitas tentativas. Aguarde alguns minutos e tente novamente.",
            status: :too_many_requests
          )
        rescue ActiveRecord::ActiveRecordError
          render_api_error(
            code: "admin_login_unavailable",
            message: "Não foi possível entrar agora. Tente novamente em instantes.",
            status: :service_unavailable
          )
        end

        private

        def render_invalid_credentials
          render_api_error(
            code: "invalid_credentials",
            message: "E-mail ou senha inválidos.",
            status: :unauthorized
          )
        end
      end
    end
  end
end
