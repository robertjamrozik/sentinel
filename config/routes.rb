# frozen_string_literal: true

Raif::Engine.routes.draw do
  resources :conversations,
    only: [:index, :show],
    controller: "/#{Raif.config.conversations_controller.constantize.controller_path}" do
    resources :conversation_entries,
      only: [:new, :create],
      as: :entries,
      path: "entries",
      controller: "/#{Raif.config.conversation_entries_controller.constantize.controller_path}"
  end

  namespace :admin do
    resources :completions, only: [:index, :show]
  end
end
