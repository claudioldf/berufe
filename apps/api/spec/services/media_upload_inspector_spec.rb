# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaUploadInspector do
  it "decodes and re-encodes a supported image with bounded dimensions" do
    body = Vips::Image.black(12, 8).pngsave_buffer

    result = described_class.new.call(body:, declared_content_type: "image/png")

    expect(result).to have_attributes(
      content_type: "image/png",
      byte_size: body.bytesize,
      width: 12,
      height: 8
    )
    decoded = Vips::Image.new_from_buffer(result.sanitized_body, "")
    expect([decoded.width, decoded.height]).to eq([12, 8])
  end

  it "rejects signature mismatches and undecodable payloads" do
    jpeg = Vips::Image.black(2, 2).jpegsave_buffer

    expect do
      described_class.new.call(body: jpeg, declared_content_type: "image/png")
    end.to raise_error(described_class::Invalid, "content_type_mismatch")
    expect do
      described_class.new.call(body: "\x89PNG\r\n\x1A\nnot-an-image".b, declared_content_type: "image/png")
    end.to raise_error(described_class::Invalid, "invalid_image")
  end

  it "rejects decoded images over the 25 megapixel boundary before re-encoding" do
    image = instance_double(Vips::Image, width: 5_001, height: 5_000)
    allow(image).to receive(:get_typeof).with("n-pages").and_return(0)
    allow(Vips::Image).to receive(:new_from_buffer).and_return(image)

    expect do
      described_class.new.call(
        body: "\xFF\xD8\xFFsynthetic".b,
        declared_content_type: "image/jpeg"
      )
    end.to raise_error(described_class::Invalid, "pixel_limit_exceeded")
  end
end
