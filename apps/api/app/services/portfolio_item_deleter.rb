# frozen_string_literal: true

class PortfolioItemDeleter
  def call(item:, now: Time.current)
    item.with_lock do
      item.update!(deleted_at: now) unless item.deleted_at?
    end
    item
  end
end
