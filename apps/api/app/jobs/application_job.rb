class ApplicationJob < ActiveJob::Base
  attr_accessor :correlation_id

  before_enqueue :set_correlation_id
  before_perform :set_correlation_id
  around_perform :with_correlation_id

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 5

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  def serialize
    super.merge("correlation_id" => correlation_id)
  end

  def deserialize(job_data)
    super
    self.correlation_id = job_data["correlation_id"]
  end

  private

  def set_correlation_id
    self.correlation_id ||= Current.request_id.presence || SecureRandom.uuid
  end

  def with_correlation_id(&block)
    Current.set(request_id: correlation_id, &block)
  end
end
