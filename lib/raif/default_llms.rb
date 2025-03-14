# frozen_string_literal: true

module Raif
  def self.default_llms
    {
      Raif::ModelCompletions::OpenAi => [
        { key: :open_ai_gpt_4o_mini, api_name: "gpt-4o-mini" },
        { key: :open_ai_gpt_4o, api_name: "gpt-4o" },
        { key: :open_ai_gpt_3_5_turbo, api_name: "gpt-3.5-turbo" },
      ],
      Raif::ModelCompletions::Anthropic => [
        { key: :anthropic_claude_3_7_sonnet, api_name: "claude-3-7-sonnet-latest", max_completion_tokens: 8192 },
        { key: :anthropic_claude_3_5_sonnet, api_name: "claude-3-5-sonnet-latest", max_completion_tokens: 8192 },
        { key: :anthropic_claude_3_5_haiku, api_name: "claude-3-5-haiku-latest", max_completion_tokens: 8192 },
        { key: :anthropic_claude_3_opus, api_name: "claude-3-opus-latest", max_completion_tokens: 4096 },
      ],
      Raif::ModelCompletions::BedrockClaude => [
        { key: :bedrock_claude_3_5_sonnet, api_name: "anthropic.claude-3-5-sonnet-20241022-v2:0", max_completion_tokens: 8192 },
        { key: :bedrock_claude_3_7_sonnet, api_name: "anthropic.claude-3-7-sonnet-20250219-v1:0", max_completion_tokens: 8192 },
        { key: :bedrock_claude_3_5_haiku, api_name: "anthropic.claude-3-5-haiku-20241022-v1:0", max_completion_tokens: 8192 },
        { key: :bedrock_claude_3_opus, api_name: "anthropic.claude-3-opus-20240229-v1:0", max_completion_tokens: 4096 },
      ]
    }
  end
end
