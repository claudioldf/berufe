# frozen_string_literal: true

class LlmSearchPrompt < ApplicationPrompt
  def initialize(services:, neighborhoods:)
    @services = services
    @neighborhoods = neighborhoods
  end

  private

  attr_reader :services, :neighborhoods

  def template_name
    "llm_search.md.erb"
  end

  def context
    {services:, neighborhoods:}
  end
end
