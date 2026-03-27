class GenerateEntryGuideWithGemini
  GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

  def initialize(entry)
    @entry = entry
    @api_key = ENV["GEMINI_API_KEY"]
  end

  def call
    raise "Missing GEMINI_API_KEY" if @api_key.blank?

    response = connection.post do |request|
      request.url GEMINI_URL
      request.headers["Content-Type"] = "application/json"
      request.headers["x-goog-api-key"] = @api_key
      request.body = build_body.to_json
    end

    raise "Gemini request failed: #{response.status} - #{response.body}" unless response.success?

    parsed_response = JSON.parse(response.body)
    text = extract_text(parsed_response)

    raise "Gemini returned empty text" if text.blank?

    guide_data = parse_guide_json(text)

    @entry.update!(
      overview: guide_data["overview"],
      steps: guide_data["steps"],
      code_example: guide_data["code_example"],
      doc_link: guide_data["doc_link"],
      tags: guide_data["tags"]
    )
  end

  private

  def connection
    Faraday.new
  end

  def build_body
    {
      contents: [
        {
          parts: [
            {
              text: prompt
            }
          ]
        }
      ]
    }
  end

  def retrieved_chunks
    @retrieved_chunks ||= RetrieveKnowledgeContext.new(
      technology: @entry.technology,
      use_case: @entry.use_case
    ).call
  end

  def retrieved_context
    retrieved_chunks.map.with_index(1) do |chunk, index|
      <<~TEXT
        Source #{index}: #{chunk.knowledge_document.title}
        #{chunk.content}
      TEXT
    end.join("\n\n")
  end

  def prompt
    context_block =
      if retrieved_chunks.any?
        <<~PROMPT
          Use the retrieved knowledge below where relevant to improve the answer.
          If the context is useful, ground the answer in it.
          If the retrieved context is incomplete, you may still use general technical knowledge to provide a helpful answer.

          Retrieved knowledge:
          #{retrieved_context}
        PROMPT
      else
        <<~PROMPT
          No stored knowledge was found for this request, so provide a helpful answer using general technical knowledge.
        PROMPT
      end

    <<~PROMPT
      You are helping a developer learn a technology for a specific use case.

      Technology: #{@entry.technology}
      Use case: #{@entry.use_case}

      #{context_block}

      Return valid JSON only.
      Do not use markdown.
      Do not wrap the JSON in triple backticks.

      Use exactly this structure:

      {
        "overview": "short explanation",
        "steps": "step-by-step guide",
        "code_example": "simple code example",
        "doc_link": "one useful official documentation link or N/A",
        "tags": "comma-separated tags"
      }

      Keep it practical, beginner-friendly, and concise.
    PROMPT
  end

  def extract_text(parsed_response)
    parts = parsed_response.dig("candidates", 0, "content", "parts")
    return "" unless parts.is_a?(Array)

    parts.map { |part| part["text"] }.compact.join("\n").strip
  end

  def parse_guide_json(text)
    cleaned_text = text.strip

    if cleaned_text.start_with?("```json")
      cleaned_text = cleaned_text.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "")
    elsif cleaned_text.start_with?("```")
      cleaned_text = cleaned_text.gsub(/\A```\s*/, "").gsub(/\s*```\z/, "")
    end

    data = JSON.parse(cleaned_text)

    unless data.is_a?(Hash)
      raise "Gemini JSON response was not an object"
    end

    {
      "overview" => data["overview"].to_s.strip,
      "steps" => data["steps"].to_s.strip,
      "code_example" => data["code_example"].to_s.strip,
      "doc_link" => data["doc_link"].to_s.strip,
      "tags" => data["tags"].to_s.strip
    }
  rescue JSON::ParserError => e
    raise "Failed to parse Gemini JSON response: #{e.message}"
  end
end