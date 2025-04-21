# frozen_string_literal: true

namespace :sentinel do
  namespace :install do
    desc "Copy migrations from Raif to host application"
    task :migrations do
      ENV["FROM"] = "sentinel"
      Rake::Task["railties:install:migrations"].invoke
    end
  end
end
