# frozen_string_literal: true

class Raif::ConversationsController < Raif::ApplicationController
  before_action :validate_conversation_type

  def show
    @conversations = conversations_scope

    @conversation = if params[:id] == "latest"
      if @conversations.any?
        @conversations.first
      else
        conversation = build_new_conversation
        conversation.save!
        conversation
      end
    else
      @conversations.find(params[:id])
    end
  end

private

  def build_new_conversation
    sentinel_conversation_type.new(creator: sentinel_current_user)
  end

  def conversations_scope
    sentinel_conversation_type.newest_first.where(creator: sentinel_current_user)
  end

  def conversation_type_param
    params[:conversation_type].presence || "Raif::Conversation"
  end

  def validate_conversation_type
    head :bad_request unless Raif.config.conversation_types.include?(conversation_type_param)
  end

  def sentinel_conversation_type
    @sentinel_conversation_type ||= begin
      unless Raif.config.conversation_types.include?(conversation_type_param)
        raise Raif::Errors::InvalidConversationTypeError,
          "Invalid Raif conversation type - not in Raif.config.conversation_types: #{conversation_type_param}"
      end

      conversation_type = conversation_type_param.constantize

      unless conversation_type == Raif::Conversation || conversation_type.ancestors.include?(Raif::Conversation)
        raise Raif::Errors::InvalidConversationTypeError,
          "Invalid Raif conversation type - not a descendant of Raif::Conversation: #{conversation_type_param}"
      end

      conversation_type
    end
  end

end
