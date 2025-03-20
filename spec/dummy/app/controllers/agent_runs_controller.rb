# frozen_string_literal: true

class AgentRunsController < ApplicationController

  def index
  end

  def create
    agent = Raif::Agent.new(
      task: params[:task],
      tools: [Raif::ModelTools::WikipediaSearchTool, Raif::ModelTools::FetchUrlTool],
      creator: current_user
    )

    agent.run! do |agent_invocation, conversation_history_entry|
      Turbo::StreamsChannel.broadcast_append_to(
        :agent_runs,
        target: "agent-progress",
        partial: "agent_runs/conversation_history_entry",
        locals: { agent_invocation: agent_invocation, conversation_history_entry: conversation_history_entry }
      )
    end
  end
end
