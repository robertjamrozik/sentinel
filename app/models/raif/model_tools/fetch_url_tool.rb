# frozen_string_literal: true

class Raif::ModelTools::FetchUrlTool < Raif::ModelTool

  def self.example_model_invocation
    {
      "name": "fetch_url",
      "arguments": [
        {
          "url": "https://en.wikipedia.org/wiki/NASA"
        }
      ]
    }
  end

  def self.tool_arguments_schema
    {
      url: {
        type: "string",
        description: "The URL to fetch"
      }
    }
  end

  def process_invocation(tool_invocation)
    url = tool_invocation.tool_arguments["url"]

    response = Faraday.get(url)

    tool_invocation.update!(
      result: {
        url: url,
        status: response.status,
        body: response.body
      }
    )

    tool_invocation.result
  end

end
