# frozen_string_literal: true

require "rails_helper"
require "vips"

RSpec.describe RegeneratedImageValidator do
  let(:body) { Vips::Image.black(12, 8).pngsave_buffer }

  it "accepts an exact supported regenerated image" do
    expect(
      described_class.new.call(
        body:,
        content_type: "image/png",
        byte_size: body.bytesize,
        width: 12,
        height: 8
      )
    ).to be(true)
  end

  it "denies signature, byte-size, dimension, and pixel-limit mismatches" do
    expect do
      described_class.new.call(
        body:,
        content_type: "image/jpeg",
        byte_size: body.bytesize,
        width: 12,
        height: 8
      )
    end.to raise_error(described_class::Invalid, "content signature changed")

    expect do
      described_class.new.call(
        body:,
        content_type: "image/png",
        byte_size: MediaUpload::MAX_BYTE_SIZE + 1,
        width: 12,
        height: 8
      )
    end.to raise_error(described_class::Invalid, "invalid byte size")

    expect do
      described_class.new.call(
        body:,
        content_type: "image/png",
        byte_size: body.bytesize,
        width: 13,
        height: 8
      )
    end.to raise_error(described_class::Invalid, "stored dimensions changed")

    expect do
      described_class.new.call(
        body:,
        content_type: "image/png",
        byte_size: body.bytesize,
        width: 5_001,
        height: 5_000
      )
    end.to raise_error(described_class::Invalid, "pixel limit exceeded")
  end
end
