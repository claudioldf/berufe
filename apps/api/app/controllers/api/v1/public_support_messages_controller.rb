# frozen_string_literal: true

module Api
  module V1
    class PublicSupportMessagesController < BaseController
      before_action :prevent_caching

      def create
        SupportMessageRateLimiter.new.check_and_increment!(
          ip_address: VisitorIpResolver.new.call(request)
        )
        SupportMessageSubmitter.new.call(attributes: support_message_params.to_h.deep_symbolize_keys)
        render json: {data: {received: true}, request_id: Current.request_id}, status: :accepted
      rescue SupportMessageRateLimiter::RateLimited => error
        response.set_header("Retry-After", error.retry_after.to_s)
        render_api_error(
          code: "support_message_rate_limited",
          message: "Muitas mensagens em pouco tempo. Tente novamente mais tarde.",
          status: :too_many_requests
        )
      rescue SupportMessageSubmitter::Invalid => error
        render_api_error(
          code: "validation_failed",
          message: "Revise os campos da mensagem.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue SupportMessageSubmitter::Unavailable
        render_api_error(
          code: "support_unavailable",
          message: "O suporte está indisponível agora. Escreva para suporte@berufe.com.br.",
          status: :service_unavailable
        )
      end

      private

      def support_message_params
        params.require(:support_message).permit(:name, :email, :phone, :message, :topic)
      end
    end
  end
end
