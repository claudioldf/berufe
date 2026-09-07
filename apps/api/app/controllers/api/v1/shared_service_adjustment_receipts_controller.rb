# frozen_string_literal: true

module Api
  module V1
    class SharedServiceAdjustmentReceiptsController < BaseController
      before_action :protect_bearer_response

      def resolve
        receipt = SharedServiceAdjustmentReceiptReader.new.call(
          token: params[:token],
          receipt_id: params[:receipt_id]
        )
        response.set_header("X-Content-Type-Options", "nosniff")
        send_data(
          receipt.body,
          type: receipt.content_type,
          disposition: "inline",
          filename: receipt.filename
        )
      rescue SharedServiceAdjustmentReceiptReader::NotFound,
        Errno::ENOENT,
        Aws::S3::Errors::NoSuchKey
        raise ActiveRecord::RecordNotFound
      end

      private

      def protect_bearer_response
        response.set_header("Cache-Control", "private, no-store")
        response.set_header("Referrer-Policy", "no-referrer")
        response.set_header("X-Robots-Tag", "noindex, nofollow")
      end
    end
  end
end
