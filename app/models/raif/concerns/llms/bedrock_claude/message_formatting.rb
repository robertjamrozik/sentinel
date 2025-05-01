# frozen_string_literal: true

module Raif::Concerns::Llms::BedrockClaude::MessageFormatting
  extend ActiveSupport::Concern

  def format_string_message(content)
    [{ "text" => content }]
  end

  def format_model_image_input_message(image_input)
    if image_input.source_type == :url
      raise Raif::Errors::UnsupportedFeatureError, "AWS Bedrock does not support providing an image by URL"
    elsif image_input.source_type == :file_content
      {
        "type" => "image",
        "source" => {
          "type" => "base64",
          "media_type" => image_input.content_type,
          "data" => image_input.base64_data
        }
      }
    else
      raise Raif::Errors::InvalidModelImageInputError, "Invalid model image input source type: #{image_input.source_type}"
    end
  end

  def format_model_file_input_message(file_input)
    if file_input.source_type == :url
      raise Raif::Errors::UnsupportedFeatureError, "AWS Bedrock does not support providing a file by URL"
    elsif file_input.source_type == :file_content
      {
        "type" => "document",
        "source" => {
          "type" => "base64",
          "media_type" => file_input.content_type,
          "data" => file_input.base64_data
        }
      }
    else
      raise Raif::Errors::InvalidModelFileInputError, "Invalid model file input source type: #{file_input.source_type}"
    end
  end
end
