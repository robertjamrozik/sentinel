# frozen_string_literal: true

class Raif::TestConversation < Raif::Conversation

  def available_model_tools
    [
      Raif::TestModelTool,
      Raif::ModelTools::WikipediaSearch
    ]
  end

end
