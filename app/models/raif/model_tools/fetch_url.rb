# frozen_string_literal: true

class Raif::ModelTools::FetchUrl < Raif::ModelTool
  tool_arguments_schema do
    string "url", description: "The URL to fetch content from"
  end

  example_model_invocation do
    {
      "name": tool_name,
      "arguments": { "url": "https://en.wikipedia.org/wiki/NASA" }
    }
  end

  tool_description do
    "Fetch a URL and return the page content as markdown"
  end

  class << self
    def observation_for_invocation(tool_invocation)
      return "No results found" unless tool_invocation.result.present?

      <<~OBSERVATION
        Result Status: #{tool_invocation.result["status"]}
        Result Content:
        #{tool_invocation.result["content"]}
      OBSERVATION
    end

    def process_invocation(tool_invocation)
      url = tool_invocation.tool_arguments["url"]
      response = Faraday.get(url)

      readable_content = Raif::Utils::ReadableContentExtractor.new(response.body).extract_readable_content
      markdown_content = Raif::Utils::HtmlToMarkdownConverter.convert(readable_content)

      tool_invocation.update!(
        result: {
          status: response.status,
          content: markdown_content
        }
      )

      tool_invocation.result
    end
  end

end
