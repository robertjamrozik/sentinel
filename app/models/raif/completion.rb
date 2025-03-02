# frozen_string_literal: true

module Raif
  class Completion < Raif::ApplicationRecord
    belongs_to :creator, polymorphic: true
    belongs_to :sentinel_conversation_entry, class_name: "Raif::ConversationEntry", optional: true

    has_many :model_tool_invocations,
      class_name: "Raif::ModelToolInvocation",
      dependent: :destroy,
      foreign_key: :sentinel_completion_id,
      inverse_of: :sentinel_completion

    enum :response_format, { text: 0, json: 1, html: 2 }, prefix: true

    boolean_timestamp :started_at
    boolean_timestamp :completed_at
    boolean_timestamp :failed_at

    validates :response_format, presence: true, inclusion: { in: response_formats.keys }
    validates :llm_model_name, presence: true, inclusion: { in: Raif.available_llm_keys.map(&:to_s) }
    validates :requested_language_key, inclusion: { in: Raif.supported_languages, allow_blank: true }

    normalizes :prompt, :response, :system_prompt, with: ->(text){ text&.strip }

    before_validation ->{ self.llm_model_name ||= default_llm }

    def self.llm_response_format(format)
      raise ArgumentError, "response_format must be one of: #{response_formats.keys.join(", ")}" unless response_formats.keys.include?(format.to_s)

      after_initialize -> { self.response_format = format }, if: :new_record?
    end

    def self.llm_completion_args(*attr_names)
      attr_names.reject{|attr| [:creator, :sentinel_conversation_entry].include?(attr) }.each do |attr_name|
        attr_accessor(attr_name)
      end
    end

    def populate_prompts
      self.requested_language_key ||= creator.preferred_language_key if creator.respond_to?(:preferred_language_key)
      self.prompt = build_prompt
      self.system_prompt = build_system_prompt
    end

    def messages
      [{ "role" => "user", "content" => prompt }]
    end

    def run
      populate_prompts

      update_columns(started_at: Time.current) if started_at.nil?
      reply = llm.chat(messages: messages, system_prompt: system_prompt)

      update({
        prompt_tokens: reply[:prompt_tokens],
        completion_tokens: reply[:completion_tokens],
        response: reply[:response]
      })

      process_model_tool_invocations
      completed!
      parsed_response
    end

    def self.run(creator:, available_model_tools: nil, llm_model_name: nil, **args)
      completion = new(creator:, llm_model_name:, available_model_tools:, started_at: Time.current, **args)
      completion.save!
      completion.run
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
      system_prompt = Raif.config.base_system_prompt || "You are a friendly assistant."
      system_prompt += " #{system_prompt_language_preference}" if requested_language_key.present?
      system_prompt
    end

    def system_prompt_language_preference
      return if requested_language_key.blank?

      "You're collaborating with teammate who speaks #{requested_language_name}. Please respond in #{requested_language_name}."
    end

    def requested_language_name
      @requested_language_name ||= I18n.t("sentinel.languages.#{requested_language_key}", locale: "en")
    end

    def default_llm
      Raif.config.default_llm
    end

    def llm
      @llm ||= Raif.llm_for_key(llm_model_name.to_sym)
    end

    def parsed_response
      @parsed_response ||= if response_format_json?
        json = response.gsub("```json", "").gsub("```", "")
        JSON.parse(json)
      elsif response_format_html?
        html = response.strip.gsub("```html", "").chomp("```")
        clean_html_fragment(html)
      else
        response.strip
      end
    end

    def clean_html_fragment(html)
      fragment = Nokogiri::HTML.fragment(html)

      fragment.traverse do |node|
        if node.text? && node.text.strip.empty?
          node.remove
        end
      end

      ActionController::Base.helpers.sanitize(fragment.to_html).strip
    end

    def available_model_tools_map
      @available_model_tools_map ||= available_model_tools&.map do |tool|
        tool_klass = tool.constantize
        [tool_klass.tool_name, tool_klass]
      end.to_h
    end

    def process_model_tool_invocations
      return unless response_format_json?
      return unless parsed_response.is_a?(Hash)
      return unless parsed_response["tools"].present? && parsed_response["tools"].is_a?(Array)

      parsed_response["tools"].each do |t|
        tool_klass = available_model_tools_map[t["name"]]
        next unless tool_klass

        tool_klass.invoke_tool(tool_arguments: t["arguments"], completion: self)
      end
    end

  end
end
