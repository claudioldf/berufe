# frozen_string_literal: true

module MediaStorage
  def self.build(settings: Rails.configuration.x.berufe.environment, environment: ENV)
    case settings.media_storage_adapter
    when "local"
      LocalDiskStorage.new(root: environment.fetch("LOCAL_STORAGE_ROOT"))
    when "r2"
      R2Storage.new(
        endpoint: environment.fetch("R2_ENDPOINT"),
        access_key_id: environment.fetch("R2_ACCESS_KEY_ID"),
        secret_access_key: environment.fetch("R2_SECRET_ACCESS_KEY"),
        private_bucket: environment.fetch("R2_PRIVATE_BUCKET")
      )
    else
      raise ArgumentError, "Unsupported media storage adapter"
    end
  end
end
