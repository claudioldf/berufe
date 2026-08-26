# frozen_string_literal: true

class LlmSearchPrompt < ApplicationPrompt
  def initialize(services:, neighborhoods:, default_location:)
    @services = services
    @neighborhoods = neighborhoods
    @default_location = default_location
  end

  private

  attr_reader :services, :neighborhoods, :default_location

  def template_name
    "llm_search.md.erb"
  end

  def context
    {services:, neighborhoods:, default_location:}
  end
end
