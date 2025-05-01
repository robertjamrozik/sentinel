# frozen_string_literal: true

RSpec.shared_examples "an LLM that uses OpenAI's message formatting" do
  describe "#format_messages" do
    it "formats the messages correctly" do
      messages = [{ "role" => "user", "content" => "Hello" }]
      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([{ "role" => "user", "content" => "Hello" }])
    end

    it "formats the messages correctly with an image" do
      image_path = Raif::Engine.root.join("spec/fixtures/files/cultivate.png")
      image = Raif::ModelImageInput.new(input: image_path)
      messages = [{
        "role" => "user",
        "content" => [
          { "text" => "Hello" },
          image
        ]
      }]

      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            { "text" => "Hello" },
            {
              "type" => "image_url",
              "image_url" => {
                "url" => "data:image/png;base64,#{Base64.strict_encode64(File.read(image_path))}"
              }
            }
          ]
        }
      ])
    end

    it "formats the messages correctly when using image_url" do
      image_url = "https://example.com/image.png"
      image = Raif::ModelImageInput.new(url: image_url)
      messages = [{ "role" => "user", "content" => [image] }]
      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            {
              "type" => "image_url",
              "image_url" => {
                "url" => image_url
              }
            }
          ]
        }
      ])
    end

    it "formats the messages correctly with a file" do
      file_path = Raif::Engine.root.join("spec/fixtures/files/test.pdf")
      file = Raif::ModelFileInput.new(input: file_path)
      messages = [{
        "role" => "user",
        "content" => [
          { "text" => "Hello" },
          file
        ]
      }]

      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            { "text" => "Hello" },
            {
              "type" => "file",
              "file" => {
                "filename" => "test.pdf",
                "file_data" => "data:application/pdf;base64,#{Base64.strict_encode64(File.read(file_path))}"
              }
            }
          ]
        }
      ])
    end

    it "raises an error when trying to use file_url" do
      file = Raif::ModelFileInput.new(url: "https://example.com/file.pdf")
      messages = [{ "role" => "user", "content" => [file] }]
      expect { llm.format_messages(messages) }.to raise_error(Raif::Errors::UnsupportedFeatureError)
    end
  end
end
