# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ModerationMediaController < ModerationBaseController
        def show
          media = ModerationMediaReader.new.call(
            target_type: params[:target_type],
            target_id: params[:target_id]
          )
          response.set_header("X-Content-Type-Options", "nosniff")
          send_data(
            media.body,
            type: media.content_type,
            disposition: "inline",
            filename: media.filename
          )
        rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
          raise ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
