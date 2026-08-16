# frozen_string_literal: true

module Api
  module V1
    class OtpVerificationsController < BaseController
      before_action :prevent_caching

      def create
        result = PhoneOtpVerifier.new.call(
          challenge_token: params[:challenge_token],
          code: params[:code]
        )
        set_application_session_cookie(session: result.session, token: result.session_token)

        render json: {
          data: {status: "verified"},
          request_id: Current.request_id
        }
      rescue PhoneOtpVerifier::Invalid
        render_invalid_verification
      rescue SmsOtp::ProviderUnavailable, SmsOtp::RateLimited, SmsOtp::DeliveryRejected,
        ActiveSupport::MessageEncryptor::InvalidMessage, ActiveRecord::ActiveRecordError
        render_api_error(
          code: "otp_provider_unavailable",
          message: "Não foi possível confirmar o código agora. Tente novamente em instantes.",
          status: :service_unavailable
        )
      end

      private

      def render_invalid_verification
        render_api_error(
          code: "invalid_otp",
          message: "Código inválido ou expirado.",
          status: :unprocessable_content
        )
      end
    end
  end
end
