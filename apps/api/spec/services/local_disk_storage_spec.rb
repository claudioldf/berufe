# frozen_string_literal: true

require "tmpdir"
require_relative "../../app/services/local_disk_storage"

RSpec.describe LocalDiskStorage do
  it "writes, reads, and deletes synthetic local media" do
    Dir.mktmpdir("berufe-storage") do |root|
      storage = described_class.new(root:)

      expect(storage.write(scope: :private, key: "profile/image.jpg", body: "synthetic")).to eq("profile/image.jpg")
      expect(storage.read(scope: :private, key: "profile/image.jpg")).to eq("synthetic")

      storage.delete(scope: :private, key: "profile/image.jpg")
      expect { storage.read(scope: :private, key: "profile/image.jpg") }.to raise_error(Errno::ENOENT)
    end
  end

  it "rejects paths that escape the configured storage root" do
    storage = described_class.new(root: "/tmp/berufe-storage")

    expect { storage.write(scope: :private, key: "../secret", body: "no") }
      .to raise_error(ArgumentError, "invalid storage key")
    expect { storage.read(scope: :unknown, key: "image.jpg") }
      .to raise_error(ArgumentError, "invalid storage scope")
  end
end
