# frozen_string_literal: true

class ChatController < ApplicationController
  def index
    # Find the latest conversation for this user or create a new one
    @conversation = Raif::Conversation.where(creator: current_user).newest_first.first

    if @conversation.nil?
      @conversation = Raif::Conversation.new(creator: current_user)
      @conversation.save!
    end
  end
end
