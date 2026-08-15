# frozen_string_literal: true

require "fileutils"
require "pathname"

class LocalDiskStorage
  SCOPES = %w[public private].freeze

  def initialize(root:)
    @root = Pathname(root).expand_path
  end

  def write(scope:, key:, body:, **)
    path = path_for(scope, key)
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, body)
    key
  end

  def read(scope:, key:)
    File.binread(path_for(scope, key))
  end

  def delete(scope:, key:)
    FileUtils.rm_f(path_for(scope, key))
  end

  private

  def path_for(scope, key)
    raise ArgumentError, "invalid storage scope" unless SCOPES.include?(scope.to_s)
    raise ArgumentError, "invalid storage key" if key.to_s.empty? || Pathname(key).absolute?

    scope_root = @root.join(scope.to_s)
    path = scope_root.join(key.to_s).cleanpath
    unless path.to_s.start_with?("#{scope_root}/")
      raise ArgumentError, "invalid storage key"
    end

    path
  end
end
