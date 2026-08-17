# frozen_string_literal: true

module Api
  module V1
    module Admin
      class VerificationFilesController < ModerationBaseController
        def show
          file = VerificationFileReader.new.call(id: params[:id])
          response.set_header("X-Content-Type-Options", "nosniff")
          send_data(
            file.body,
            type: file.content_type,
            disposition: "inline",
            filename: file.filename
          )
        rescue VerificationFileReader::Unavailable, Errno::ENOENT, Aws::S3::Errors::NoSuchKey
          raise ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
