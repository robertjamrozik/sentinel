# frozen_string_literal: true

require "spec_helper"
require "generators/sentinel/install/install_generator"

RSpec.describe Raif::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before do
    prepare_destination
  end

  it "creates the migration file" do
    run_generator
    expect(destination_root).to have_structure {
      directory "db" do
        directory "migrate" do
          migration "create_sentinel_tables"
        end
      end
    }

    migration_file = migration_file_name("create_sentinel_tables")
    expect(File.read(migration_file)).to include("create_table :sentinel_completions")
    expect(File.read(migration_file)).to include("create_table :sentinel_conversation_entries")
    expect(File.read(migration_file)).to include("create_table :sentinel_conversations")
    expect(File.read(migration_file)).to include("create_table :sentinel_model_tool_invocations")
    expect(File.read(migration_file)).to include("create_table :sentinel_user_tool_invocations")
  end

private

  def migration_file_name(migration_name)
    Dir.glob("#{destination_root}/db/migrate/*_#{migration_name}.rb").first
  end
end
