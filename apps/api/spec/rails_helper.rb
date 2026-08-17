# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["BERUFE_ENV"] = "test"
ENV["SMS_OTP_ADAPTER"] = "fake"
ENV["MEDIA_STORAGE_ADAPTER"] = "local"
ENV["DATABASE_URL"] = ENV.fetch("TEST_DATABASE_URL")
ENV["OTP_RESEND_COOLDOWN_SECONDS"] = "30"
ENV["OTP_DAILY_PHONE_LIMIT"] = "5"
ENV["OTP_DAILY_IP_LIMIT"] = "20"
ENV["OTP_CHALLENGE_TTL_SECONDS"] = "600"

require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "openapi_first"

ActiveRecord::Migration.maintain_test_schema!

contract_path = ENV.fetch("OPENAPI_CONTRACT_PATH") do
  Rails.root.join("../contracts/openapi.yaml").to_s
end
OpenapiFirst::Test.setup do |test|
  test.register(contract_path)
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include OpenapiFirst::Test::Methods[Rails.application], openapi: true
end
