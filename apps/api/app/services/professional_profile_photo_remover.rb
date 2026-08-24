# frozen_string_literal: true

class ProfessionalProfilePhotoRemover
  def initialize(publisher: ModerationMediaPublisher.new)
    @publisher = publisher
  end

  def call(profile:, now: Time.current)
    public_keys = []

    profile.with_lock do
      active_photos = [
        profile.working_photo,
        profile.published_photo,
        profile.approved_photo
      ].compact.uniq(&:id)

      profile.update!(
        working_photo: nil,
        published_photo: nil,
        approved_photo: nil
      )
      active_photos.each do |photo|
        next unless photo.status.in?(%w[pending_review approved])

        public_keys << photo.public_key if photo.public_key.present?
        photo.update!(
          status: "superseded",
          public_key: nil,
          reviewed_at: now
        )
      end
    end

    public_keys.each { |public_key| publisher.delete(public_key) }
    profile
  end

  private

  attr_reader :publisher
end
