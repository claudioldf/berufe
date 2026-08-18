# frozen_string_literal: true

require "vips"

class RegeneratedImageValidator
  class Invalid < StandardError; end

  def call(body:, content_type:, byte_size:, width:, height:)
    raise Invalid, "invalid byte size" unless byte_size.between?(1, MediaUpload::MAX_BYTE_SIZE)
    raise Invalid, "stored byte size changed" unless body.bytesize == byte_size
    raise Invalid, "invalid dimensions" unless width.positive? && height.positive?
    raise Invalid, "pixel limit exceeded" if width * height > MediaUpload::MAX_PIXELS
    raise Invalid, "content signature changed" unless content_type_from_signature(body) == content_type

    image = Vips::Image.new_from_buffer(body, "", access: :sequential, fail_on: :error)
    raise Invalid, "multiple image frames" if number_of_pages(image) > 1
    raise Invalid, "stored dimensions changed" unless image.width == width && image.height == height

    true
  rescue Invalid
    raise
  rescue Vips::Error, TypeError, ArgumentError
    raise Invalid, "invalid image"
  end

  private

  def content_type_from_signature(body)
    return "image/jpeg" if body.start_with?("\xFF\xD8\xFF".b)
    "image/png" if body.start_with?("\x89PNG\r\n\x1A\n".b)
  end

  def number_of_pages(image)
    image.get_typeof("n-pages").zero? ? 1 : image.get("n-pages")
  end
end
