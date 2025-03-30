# frozen_string_literal: true

class AgentInvocationsController < ApplicationController

  def index
  end

  def create
    agent_invocation = Raif::AgentInvocations::ReActAgent.new(
      task: params[:task],
      available_model_tools: [Raif::ModelTools::WikipediaSearch, Raif::ModelTools::FetchUrl],
      creator: current_user
    )

    agent_invocation.run! do |conversation_history_entry|
      Turbo::StreamsChannel.broadcast_append_to(
        :agent_invocations,
        target: "agent-progress",
        partial: "agent_invocations/conversation_history_entry",
        locals: { agent_invocation: agent_invocation, conversation_history_entry: conversation_history_entry }
      )
    end

    head :no_content
  end
end
