# frozen_string_literal: true

module Api
  module V1
    class OtpChallengesController < BaseController
      before_action :prevent_caching
      def create
        result = PhoneOtpChallengeStarter.new.call(
          phone: params[:phone],
          ip_address: request.remote_ip
        )

        render json: {
          data: {
            status: "accepted",
            challenge_token: result.challenge_token,
            expires_in: result.expires_in,
            resend_available_in: result.resend_available_in
          },
          request_id: Current.request_id
        }, status: :created
      rescue BrazilianPhoneNumber::Invalid
        render_api_error(
          code: "invalid_phone",
          message: "Digite um número brasileiro válido.",
          status: :unprocessable_content,
          field_errors: {phone: ["não é válido"]}
        )
      rescue OtpRequestRateLimiter::RateLimited => exception
        response.set_header("Retry-After", exception.retry_after.to_s)
        render_api_error(
          code: "otp_rate_limited",
          message: rate_limit_message(exception),
          status: :too_many_requests
        )
      rescue SmsOtp::RateLimited => exception
        retry_after = positive_retry_after(exception.retry_after)
        response.set_header("Retry-After", retry_after.to_s)
        render_api_error(
          code: "otp_rate_limited",
          message: "Muitas solicitações. Aguarde antes de tentar novamente.",
          status: :too_many_requests
        )
      rescue SmsOtp::DeliveryRejected
        render_api_error(
          code: "otp_delivery_rejected",
          message: "Não foi possível enviar o código para este número. Revise-o e tente novamente.",
          status: :unprocessable_content
        )
      rescue SmsOtp::ProviderUnavailable, ActiveRecord::ActiveRecordError
        render_api_error(
          code: "otp_provider_unavailable",
          message: "Não foi possível enviar o código agora. Tente novamente em instantes.",
          status: :service_unavailable
        )
      end

      private

      def rate_limit_message(exception)
        if exception.reason == "cooldown"
          "Aguarde antes de pedir outro código."
        else
          "Limite diário de códigos atingido. Tente novamente amanhã."
        end
      end

      def positive_retry_after(value)
        parsed = Integer(value.to_s, 10)
        parsed.positive? ? parsed : 60
      rescue ArgumentError
        60
      end
    end
  end
end
