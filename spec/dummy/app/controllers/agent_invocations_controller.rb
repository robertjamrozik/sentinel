# frozen_string_literal: true

class AgentInvocationsController < ApplicationController

  def index
  end

  def create
    agent = Raif::AgentInvocation.new(
      task: params[:task],
      available_model_tools: [Raif::ModelTools::WikipediaSearchTool, Raif::ModelTools::FetchUrlTool],
      creator: current_user
    )

    agent.run! do |agent_invocation, conversation_history_entry|
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
