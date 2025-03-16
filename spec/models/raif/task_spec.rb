# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Task, type: :model do
  describe "#requested_language_key" do
    it "does not permit invalid language keys" do
      task = FB.build(:sentinel_task, requested_language_key: "invalid")
      expect(task.valid?).to eq(false)
      expect(task.errors[:requested_language_key]).to include("is not included in the list")
    end
  end

  describe "#llm_model_key" do
    it "does not permit invalid model names" do
      task = FB.build(:sentinel_task, llm_model_key: "invalid")
      expect(task.valid?).to eq(false)
      expect(task.errors[:llm_model_key]).to include("is not included in the list")
    end
  end

  describe ".run" do
    let(:user) { FB.create(:sentinel_test_user) }
    context "for a task requesting a text response" do
      before do
        stub_sentinel_task(Raif::TestTask) do |_messages|
          "Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense."
        end
      end

      context "when no language preference is set" do
        it "runs the task" do
          task = Raif::TestTask.run(creator: user)
          expect(task).to be_persisted
          expect(task.creator).to eq(user)
          expect(task.started_at).to be_present
          expect(task.completed_at).to be_present
          expect(task.prompt).to eq("Tell me a joke")
          expect(task.system_prompt).to eq("You are a helpful assistant.\nYou are also good at telling jokes.")
          expect(task.response_format).to eq("text")
          expect(task.response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
          expect(task.parsed_response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
          expect(task.requested_language_key).to be_nil

          expect(task.sentinel_model_completion).to be_persisted
          expect(task.sentinel_model_completion.source).to eq(task)
          expect(task.sentinel_model_completion.raw_response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
        end
      end

      context "when a language preference is set" do
        it "runs the task" do
          task = Raif::TestTask.run(creator: user, requested_language_key: "es")
          expect(task).to be_persisted
          expect(task.creator).to eq(user)
          expect(task.started_at).to be_present
          expect(task.completed_at).to be_present
          expect(task.prompt).to eq("Tell me a joke")
          expect(task.system_prompt).to eq("You are a helpful assistant.\nYou're collaborating with teammate who speaks Spanish. Please respond in Spanish.\nYou are also good at telling jokes.") # rubocop:disable Layout/LineLength
          expect(task.response_format).to eq("text")
          expect(task.response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
          expect(task.parsed_response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
          expect(task.requested_language_key).to eq("es")

          expect(task.sentinel_model_completion).to be_persisted
          expect(task.sentinel_model_completion.source).to eq(task)
          expect(task.sentinel_model_completion.raw_response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
        end
      end

      context "when the creator has a language preference" do
        it "runs the task" do
          allow(user).to receive(:preferred_language_key).and_return("de")
          task = Raif::TestTask.run(creator: user)
          expect(task).to be_persisted
          expect(task.creator).to eq(user)
          expect(task.started_at).to be_present
          expect(task.completed_at).to be_present
          expect(task.prompt).to eq("Tell me a joke")
          expect(task.system_prompt).to eq("You are a helpful assistant.\nYou're collaborating with teammate who speaks German. Please respond in German.\nYou are also good at telling jokes.") # rubocop:disable Layout/LineLength
          expect(task.response_format).to eq("text")
          expect(task.response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
          expect(task.parsed_response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
          expect(task.requested_language_key).to eq("de")

          expect(task.sentinel_model_completion).to be_persisted
          expect(task.sentinel_model_completion.source).to eq(task)
          expect(task.sentinel_model_completion.raw_response).to eq("Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.") # rubocop:disable Layout/LineLength
        end
      end
    end

    context "for a task requesting a JSON response" do
      before do
        stub_sentinel_task(Raif::TestJsonTask) do |_messages|
          {
            joke: "Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.",
            answer: "R"
          }.to_json
        end
      end

      it "runs the task" do
        task = Raif::TestJsonTask.run(creator: user)
        expect(task).to be_persisted
        expect(task.creator).to eq(user)
        expect(task.started_at).to be_present
        expect(task.completed_at).to be_present
        expect(task.prompt).to eq("Tell me a joke")
        expect(task.system_prompt).to eq("You are a helpful assistant.\nYou are also good at telling jokes. Your response should be a JSON object with the following keys: joke, answer.") # rubocop:disable Layout/LineLength
        expect(task.response_format).to eq("json")
        expect(task.response).to eq("{\"joke\":\"Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.\",\"answer\":\"R\"}") # rubocop:disable Layout/LineLength

        expect(task.sentinel_model_completion).to be_persisted
        expect(task.sentinel_model_completion.source).to eq(task)
        expect(task.sentinel_model_completion.raw_response).to eq("{\"joke\":\"Why is a pirate's favorite letter 'R'? Because, if you think about it, 'R' is the only letter that makes sense.\",\"answer\":\"R\"}") # rubocop:disable Layout/LineLength
      end
    end

    context "for a task requesting an HTML response" do
      before do
        stub_sentinel_task(Raif::TestHtmlTask) do |_messages|
          "<p>Why is a pirate's favorite letter 'R'?</p><p>Because, if you think about it, <strong>'R'</strong> is the only letter that makes sense.</p>" # rubocop:disable Layout/LineLength
        end
      end

      it "runs the task" do
        task = Raif::TestHtmlTask.run(creator: user)
        expect(task).to be_persisted
        expect(task.creator).to eq(user)
        expect(task.started_at).to be_present
        expect(task.completed_at).to be_present
        expect(task.prompt).to eq("Tell me a joke")
        expect(task.system_prompt).to eq("You are a helpful assistant.\nYou are also good at telling jokes. Your response should be an HTML snippet that is formatted with basic HTML tags.") # rubocop:disable Layout/LineLength
        expect(task.response_format).to eq("html")
        expect(task.response).to eq("<p>Why is a pirate's favorite letter 'R'?</p><p>Because, if you think about it, <strong>'R'</strong> is the only letter that makes sense.</p>") # rubocop:disable Layout/LineLength

        expect(task.sentinel_model_completion).to be_persisted
        expect(task.sentinel_model_completion.source).to eq(task)
        expect(task.sentinel_model_completion.raw_response).to eq("<p>Why is a pirate's favorite letter 'R'?</p><p>Because, if you think about it, <strong>'R'</strong> is the only letter that makes sense.</p>") # rubocop:disable Layout/LineLength
      end
    end
  end
end
