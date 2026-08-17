# frozen_string_literal: true

class RequestIdSanitizer
  HEADER = "HTTP_X_REQUEST_ID"
  VALID_REQUEST_ID = /\A[A-Za-z0-9._-]{1,100}\z/

  def initialize(app)
    @app = app
  end

  def call(environment)
    request_id = environment[HEADER]
    environment.delete(HEADER) if request_id && !VALID_REQUEST_ID.match?(request_id)
    @app.call(environment)
  end
end
