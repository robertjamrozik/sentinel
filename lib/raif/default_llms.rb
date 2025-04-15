# frozen_string_literal: true

module Raif
  def self.default_llms
    {
      Raif::Llms::OpenAi => [
        {
          key: :open_ai_gpt_4o_mini,
          api_name: "gpt-4o-mini",
          input_token_cost: 0.15 / 1_000_000,
          output_token_cost: 0.6 / 1_000_000,
        },
        {
          key: :open_ai_gpt_4o,
          api_name: "gpt-4o",
          input_token_cost: 2.5 / 1_000_000,
          output_token_cost: 10.0 / 1_000_000,
        },
        {
          key: :open_ai_gpt_3_5_turbo,
          api_name: "gpt-3.5-turbo",
          input_token_cost: 0.5 / 1_000_000,
          output_token_cost: 1.5 / 1_000_000,
          model_provider_settings: { supports_structured_outputs: false }
        },
        {
          key: :open_ai_gpt_4_1,
          api_name: "gpt-4.1",
          input_token_cost: 2.0 / 1_000_000,
          output_token_cost: 8.0 / 1_000_000,
        },
        {
          key: :open_ai_gpt_4_1_mini,
          api_name: "gpt-4.1-mini",
          input_token_cost: 0.4 / 1_000_000,
          output_token_cost: 1.6 / 1_000_000,
        },
        {
          key: :open_ai_gpt_4_1_nano,
          api_name: "gpt-4.1-nano",
          input_token_cost: 0.1 / 1_000_000,
          output_token_cost: 0.4 / 1_000_000,
        },
      ],
      Raif::Llms::Anthropic => [
        {
          key: :anthropic_claude_3_7_sonnet,
          api_name: "claude-3-7-sonnet-latest",
          input_token_cost: 3.0 / 1_000_000,
          output_token_cost: 15.0 / 1_000_000,
          max_completion_tokens: 8192
        },
        {
          key: :anthropic_claude_3_5_sonnet,
          api_name: "claude-3-5-sonnet-latest",
          input_token_cost: 3.0 / 1_000_000,
          output_token_cost: 15.0 / 1_000_000,
          max_completion_tokens: 8192
        },
        {
          key: :anthropic_claude_3_5_haiku,
          api_name: "claude-3-5-haiku-latest",
          input_token_cost: 0.8 / 1_000_000,
          output_token_cost: 4.0 / 1_000_000,
          max_completion_tokens: 8192
        },
        {
          key: :anthropic_claude_3_opus,
          api_name: "claude-3-opus-latest",
          input_token_cost: 15.0 / 1_000_000,
          output_token_cost: 75.0 / 1_000_000,
          max_completion_tokens: 4096
        },
      ],
      Raif::Llms::BedrockClaude => [
        {
          key: :bedrock_claude_3_5_sonnet,
          api_name: "anthropic.claude-3-5-sonnet-20241022-v2:0",
          input_token_cost: 0.003 / 1000,
          output_token_cost: 0.015 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_7_sonnet,
          api_name: "anthropic.claude-3-7-sonnet-20250219-v1:0",
          input_token_cost: 0.003 / 1000,
          output_token_cost: 0.015 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_5_haiku,
          api_name: "anthropic.claude-3-5-haiku-20241022-v1:0",
          input_token_cost: 0.0008 / 1000,
          output_token_cost: 0.004 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_opus,
          api_name: "anthropic.claude-3-opus-20240229-v1:0",
          input_token_cost: 0.015 / 1000,
          output_token_cost: 0.075 / 1000,
          max_completion_tokens: 4096
        },
      ]
    }
  end
end
