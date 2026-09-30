# frozen_string_literal: true

module Api
  module V1
    class OtpChallengesController < BaseController
      before_action :prevent_caching
      def create
        result = start_challenge

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
          message: "Digite um número de celular válido.",
          status: :unprocessable_content,
          field_errors: {phone: ["não é válido"]}
        )
      rescue ProfessionalEmail::Invalid
        render_api_error(
          code: "invalid_email",
          message: "Digite um e-mail válido.",
          status: :unprocessable_content,
          field_errors: {email: ["não é válido"]}
        )
      rescue ActionController::ParameterMissing
        render_api_error(
          code: "invalid_otp_destination",
          message: "Escolha celular ou e-mail para receber o código.",
          status: :unprocessable_content
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
      rescue EmailOtp::DeliveryRejected
        render_api_error(
          code: "otp_delivery_rejected",
          message: "Não foi possível enviar o código para este e-mail. Revise-o e tente novamente.",
          status: :unprocessable_content
        )
      rescue SmsOtp::ProviderUnavailable, EmailOtp::ProviderUnavailable,
        ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "otp_provider_unavailable",
          message: "Não foi possível enviar o código agora. Tente novamente em instantes.",
          status: :service_unavailable
        )
      end

      private

      def start_challenge
        if params.key?(:phone) && !params.key?(:email)
          PhoneOtpChallengeStarter.new.call(
            phone: params[:phone],
            ip_address: request.remote_ip
          )
        elsif params.key?(:email) && !params.key?(:phone)
          EmailOtpChallengeStarter.new.call(
            email: params[:email],
            ip_address: request.remote_ip
          )
        else
          raise ActionController::ParameterMissing, :phone_or_email
        end
      end

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
