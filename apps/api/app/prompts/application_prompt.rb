# frozen_string_literal: true

require "digest"
require "erb"

class ApplicationPrompt
  def render
    ERB.new(template_path.read, trim_mode: "-").result_with_hash(context)
  end

  def digest
    Digest::SHA256.hexdigest(render)
  end

  private

  def template_path
    Rails.root.join("app/prompts/templates", template_name)
  end

  def context
    {}
  end

  def template_name
    raise NotImplementedError
  end
end
