# frozen_string_literal: true

module Raif
  class Completion < Raif::ApplicationRecord
    include Raif::Concerns::HasLlm
    include Raif::Concerns::HasRequestedLanguage
    include Raif::Concerns::InvokesModelTools

    belongs_to :creator, polymorphic: true

    has_one :sentinel_model_response, as: :source, dependent: :destroy, class_name: "Raif::ModelResponse"

    enum :response_format, Raif::Llm.valid_response_formats, prefix: true

    boolean_timestamp :started_at
    boolean_timestamp :completed_at
    boolean_timestamp :failed_at

    validates :response_format, presence: true, inclusion: { in: response_formats.keys }

    normalizes :prompt, :response, :system_prompt, with: ->(text){ text&.strip }

    delegate :parsed_response, to: :sentinel_model_response, allow_nil: true

    def self.llm_response_format(format)
      raise ArgumentError, "response_format must be one of: #{response_formats.keys.join(", ")}" unless response_formats.keys.include?(format.to_s)

      after_initialize -> { self.response_format = format }, if: :new_record?
    end

    def populate_prompts
      self.requested_language_key ||= creator.preferred_language_key if creator.respond_to?(:preferred_language_key)
      self.prompt = build_prompt
      self.system_prompt = build_system_prompt
    end

    def run
      update_columns(started_at: Time.current) if started_at.nil?

      populate_prompts
      messages = [{ "role" => "user", "content" => prompt }]
      self.sentinel_model_response = llm.chat(messages: messages, source: self, system_prompt: system_prompt, response_format: response_format.to_sym)

      update(response: sentinel_model_response.raw_response)

      process_model_tool_invocations
      completed!
      self
    end

    def self.run(creator:, available_model_tools: nil, llm_model_key: nil, **args)
      completion = new(creator:, llm_model_key:, available_model_tools:, started_at: Time.current, **args)
      completion.save!
      completion.run
      completion
    rescue StandardError => e
      completion&.failed!

      logger.error e.message
      logger.error e.backtrace.join("\n")

      if defined?(Airbrake)
        notice = Airbrake.build_notice(e)
        notice[:context][:component] = "sentinel_completion"
        notice[:context][:action] = name

        Airbrake.notify(notice)
      end

      nil
    end

    def self.prompt(creator:, **args)
      new(creator:, **args).prompt
    end

    def build_prompt
      raise NotImplementedError, "Completion subclasses must implement #build_prompt"
    end

    def self.system_prompt(creator:, **args)
      new(creator:, **args).system_prompt
    end

    def build_system_prompt
      sp = Raif.config.completion_system_prompt_intro
      sp += system_prompt_language_preference if requested_language_key.present?
      sp
    end

    def process_model_tool_invocations
      return unless response_format_json?
      return unless parsed_response.is_a?(Hash)
      return unless parsed_response["tools"].present? && parsed_response["tools"].is_a?(Array)

      parsed_response["tools"].each do |t|
        tool_klass = available_model_tools_map[t["name"]]
        next unless tool_klass

        tool_klass.invoke_tool(tool_arguments: t["arguments"], source: self)
      end
    end

  end
end
