# frozen_string_literal: true

class ProfessionalHeadlineBioPrompt < ApplicationPrompt
  def initialize(display_name:, city:, state_abbreviation:, services:, years_experience:)
    @display_name = display_name
    @city = city
    @state_abbreviation = state_abbreviation
    @services = services
    @years_experience = years_experience
  end

  private

  attr_reader :display_name, :city, :state_abbreviation, :services, :years_experience

  def template_name
    "professional_headline_bio.md.erb"
  end

  def context
    {display_name:, city:, state_abbreviation:, services:, years_experience:}
  end
end
