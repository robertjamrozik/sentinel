# frozen_string_literal: true

class Raif::ConversationsController < Raif::ApplicationController
  before_action :validate_conversation_type

  def show
    @conversations = sentinel_conversations_scope(sentinel_current_user)

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

  def sentinel_conversations_scope(sentinel_current_user)
    if Raif.config.conversations_scope.respond_to?(:call)
      instance_exec(sentinel_current_user, &Raif.config.conversations_scope)
    else
      sentinel_conversation_type.newest_first.where(creator: sentinel_current_user)
    end
  end

  def validate_conversation_type
    head :bad_request unless Raif.config.conversation_types.include?(params[:conversation_type])
  end

  def sentinel_conversation_type
    @sentinel_conversation_type ||= begin
      unless Raif.config.conversation_types.include?(params[:conversation_type])
        raise Raif::Errors::InvalidConverastionTypeError,
          "Invalid Raif conversation type - not in Raif.config.conversation_types: #{params[:conversation_type]}"
      end

      conversation_type = params[:conversation_type].constantize

      unless conversation_type.ancestors.include?(Raif::Conversation)
        raise Raif::Errors::InvalidConverastionTypeError,
          "Invalid Raif conversation type - not a descendant of Raif::Conversation: #{params[:conversation_type]}"
      end

      conversation_type
    end
  end

end
