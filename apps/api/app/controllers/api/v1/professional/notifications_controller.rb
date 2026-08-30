# frozen_string_literal: true

module Api
  module V1
    module Professional
      class NotificationsController < BaseController
        prepend_before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          authorize Notification, :index?
          result = ProfessionalNotificationIndexQuery.new.call(
            scope: policy_scope(Notification),
            cursor: params[:cursor],
            limit: params[:limit]
          )
          render json: {
            data: {
              notifications: result.notifications.map { |notification| ProfessionalNotificationSerializer.new(notification) },
              unread_count: result.unread_count,
              next_cursor: result.next_cursor
            },
            request_id: Current.request_id
          }
        rescue ProfessionalNotificationIndexQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a paginação das notificações.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def read
          notification = policy_scope(Notification).find(params[:id])
          authorize notification, :update?
          notification.with_lock do
            notification.update!(status: "read", read_at: Time.current) if notification.unread?
          end
          render json: {
            data: {
              notification: ProfessionalNotificationSerializer.new(notification.reload),
              unread_count: policy_scope(Notification).unread.count
            },
            request_id: Current.request_id
          }
        end

        def read_all
          authorize Notification, :index?
          started_at = Time.current
          scope = policy_scope(Notification)
          marked_read_count = ApplicationRecord.transaction do
            ids = scope.unread.where(created_at: ..started_at).pluck(:id)
            scope.where(id: ids, status: "unread").update_all(
              status: "read",
              read_at: started_at,
              updated_at: started_at
            )
          end
          render json: {
            data: {
              marked_read_count:,
              unread_count: scope.unread.count
            },
            request_id: Current.request_id
          }
        end
      end
    end
  end
end
