# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["BERUFE_ENV"] = "test"
ENV["DATABASE_URL"] = ENV.fetch("TEST_DATABASE_URL")

require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
