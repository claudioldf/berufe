# frozen_string_literal: true

class ProfessionalNotificationIndexQuery
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 50
  Result = Data.define(:notifications, :unread_count, :next_cursor)

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional notification pagination")
    end
  end

  def initialize(cursor: ProfessionalNotificationCursor.new)
    @cursor = cursor
  end

  def call(scope:, cursor: nil, limit: DEFAULT_LIMIT)
    normalized_limit = Integer(limit.to_s.presence || DEFAULT_LIMIT, exception: false)
    errors = {}
    errors[:limit] = ["deve estar entre 1 e #{MAX_LIMIT}"] unless normalized_limit&.between?(1, MAX_LIMIT)

    cursor_context = nil
    if cursor.present?
      cursor_context = @cursor.verify(cursor)
      errors[:cursor] = ["não é válido"] unless cursor_context
    end
    raise Invalid.new(errors) if errors.any?

    unread_scope = scope.unread
    page_scope = unread_scope.newest_first
    if cursor_context
      page_scope = page_scope.where(
        "occurred_at < :occurred_at OR (occurred_at = :occurred_at AND id < :id)",
        occurred_at: cursor_context.occurred_at,
        id: cursor_context.id
      )
    end
    records = page_scope.limit(normalized_limit + 1).to_a
    has_more = records.length > normalized_limit
    notifications = records.first(normalized_limit)

    Result.new(
      notifications:,
      unread_count: unread_scope.count,
      next_cursor: has_more ? @cursor.issue(notifications.last) : nil
    )
  end
end
