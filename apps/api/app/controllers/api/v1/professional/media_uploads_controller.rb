# frozen_string_literal: true

module Api
  module V1
    module Professional
      class MediaUploadsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!
        before_action :set_profile
        before_action :set_upload, except: :create
        before_action :reject_impersonated_verification_upload!

        def create
          authorize @profile, :update?
          upload, instruction = MediaUploadAuthorizer.new.call(
            profile: @profile,
            purpose: params.require(:purpose),
            content_type: params.require(:content_type),
            byte_size: params.require(:byte_size)
          )
          render json: serialized_response(upload, instruction:), status: :created
        rescue MediaUploadAuthorizer::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Selecione uma imagem JPEG ou PNG de até 10 MiB.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        rescue MediaUploadAuthorizer::Unavailable => error
          render_unavailable(error)
        end

        def show
          authorize @upload, :show?
          render json: serialized_response(@upload)
        end

        def content
          authorize @upload, :update?
          body = request.body.read(MediaUpload::MAX_BYTE_SIZE + 1)
          MediaUploadReceiver.new.call(
            upload: @upload,
            body:,
            content_type: request.media_type
          )
          render json: serialized_response(@upload.reload)
        rescue MediaUploadReceiver::Rejected => error
          render_rejected(error.code)
        rescue MediaUploadReceiver::Unavailable => error
          render_unavailable(error)
        end

        def completion
          authorize @upload, :update?
          MediaUploadCompleter.new.call(upload: @upload)
          render json: serialized_response(@upload.reload), status: :accepted
        rescue MediaUploadCompleter::Rejected => error
          render_rejected(error.code)
        rescue MediaUploadCompleter::Unavailable => error
          render_unavailable(error)
        end

        def retry
          authorize @upload, :update?
          MediaUploadRetry.new.call(upload: @upload)
          render json: serialized_response(@upload.reload), status: :accepted
        rescue MediaUploadRetry::Rejected => error
          render_rejected(error.message)
        rescue MediaUploadRetry::Unavailable => error
          render_unavailable(error)
        end

        private

        def set_profile
          @profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless @profile
        end

        def set_upload
          @upload = @profile.media_uploads.find(params[:id])
        end

        def reject_impersonated_verification_upload!
          identity_purpose = (action_name == "create") ? params[:purpose] : @upload&.purpose
          return unless identity_purpose == "verification_identity"

          reject_impersonated_action!
        end

        def serialized_response(upload, instruction: nil)
          data = {media_upload: MediaUploadSerializer.new(upload).as_json}
          data[:upload] = instruction if instruction
          {data:, request_id: Current.request_id}
        end

        def render_rejected(code)
          conflict = code.in?(%w[upload_not_authorized upload_not_completable upload_not_retryable])
          render_api_error(
            code:,
            message: "Não foi possível concluir este envio. Selecione a imagem novamente.",
            status: conflict ? :conflict : :unprocessable_entity
          )
        end

        def render_unavailable(error)
          report_service_error(error)
          render_api_error(
            code: "media_unavailable",
            message: "O processamento da imagem está indisponível. Tente novamente.",
            status: :service_unavailable
          )
        end
      end
    end
  end
end
