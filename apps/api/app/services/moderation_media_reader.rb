# frozen_string_literal: true

class ModerationMediaReader
  Result = Data.define(:body, :content_type, :filename)
  TARGET_MODELS = {
    "profile_photo" => ProfessionalProfilePhoto,
    "portfolio_item" => PortfolioItem
  }.freeze

  def initialize(context: Current.admin_action_context, storage: MediaStorage.build)
    @context = context
    @storage = storage
  end

  def call(target_type:, target_id:)
    model = TARGET_MODELS.fetch(target_type.to_s) { raise ActiveRecord::RecordNotFound, "moderation media" }
    target = model.find(target_id)
    raise ActiveRecord::RecordNotFound if target.is_a?(PortfolioItem) && target.deleted_at

    body = storage.read(scope: :private, key: target.private_key)
    ModerationMediaAccessEvent.create!(
      admin_user_id: context.admin_user_id,
      target_type:,
      target_id: target.id,
      request_id: context.request_id,
      created_at: Time.current
    )
    extension = (target.content_type == "image/png") ? "png" : "jpg"
    Result.new(body:, content_type: target.content_type, filename: "berufe-analise-#{target_type}-#{target.id}.#{extension}")
  end

  private

  attr_reader :context, :storage
end
