# frozen_string_literal: true

require "vips"

class MediaUploadInspector
  class Invalid < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super
    end
  end

  Result = Data.define(:content_type, :byte_size, :width, :height, :sanitized_body)

  def call(body:, declared_content_type:)
    content_type = content_type_from_signature(body)
    raise Invalid, "invalid_signature" unless content_type
    raise Invalid, "content_type_mismatch" unless content_type == declared_content_type

    image = Vips::Image.new_from_buffer(body, "", access: :sequential, fail_on: :error)
    raise Invalid, "multiple_image_frames" if number_of_pages(image) > 1
    raise Invalid, "pixel_limit_exceeded" if image.width * image.height > MediaUpload::MAX_PIXELS

    normalized = image.autorot
    sanitized_body = encode(normalized, content_type)
    raise Invalid, "sanitized_image_too_large" if sanitized_body.bytesize > MediaUpload::MAX_BYTE_SIZE

    Result.new(
      content_type:,
      byte_size: body.bytesize,
      width: normalized.width,
      height: normalized.height,
      sanitized_body:
    )
  rescue Invalid
    raise
  rescue Vips::Error, TypeError, ArgumentError
    raise Invalid, "invalid_image"
  end

  private

  def content_type_from_signature(body)
    return "image/jpeg" if body.start_with?("\xFF\xD8\xFF".b)
    "image/png" if body.start_with?("\x89PNG\r\n\x1A\n".b)
  end

  def number_of_pages(image)
    image.get_typeof("n-pages").zero? ? 1 : image.get("n-pages")
  end

  def encode(image, content_type)
    case content_type
    when "image/jpeg"
      image.jpegsave_buffer(Q: 85, strip: true, interlace: true, optimize_coding: true)
    when "image/png"
      image.pngsave_buffer(compression: 9, strip: true)
    end
  end
end
