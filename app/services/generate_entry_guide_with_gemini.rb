class GenerateEntryGuideWithGemini
  GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

  def initialize(entry)
    @entry = entry
    @api_key = ENV["GEMINI_API_KEY"]
  end

  def call
    raise "Missing GEMINI_API_KEY" if @api_key.nil? || @api_key.empty?

    response = connection.post do |request|
      request.url GEMINI_URL
      request.headers["Content-Type"] = "application/json"
      request.headers["x-goog-api-key"] = @api_key
      request.body = build_body.to_json
    end

    raise "Gemini request failed: #{response.status} - #{response.body}" unless response.success?

    parsed_response = JSON.parse(response.body)
    text = extract_text(parsed_response)

    structured_content = parse_sections(text)

    @entry.update!(
      overview: structured_content[:overview],
      steps: structured_content[:steps],
      code_example: structured_content[:code_example],
      doc_link: structured_content[:doc_link],
      tags: structured_content[:tags]
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
    base_prompt = <<~PROMPT
      You are helping a developer learn a technology for a specific use case.

      Technology: #{@entry.technology}
      Use case: #{@entry.use_case}
    PROMPT

    context_prompt =
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

    format_prompt = <<~PROMPT
      Return the response in exactly this format and with these exact headings:

      OVERVIEW:
      <short explanation>

      STEPS:
      <step-by-step guide>

      CODE EXAMPLE:
      <simple code example>

      DOC LINK:
      <one useful official documentation link if known, otherwise write N/A>

      TAGS:
      <comma-separated tags>

      Do not use markdown headings.
      Do not add extra sections.
      Keep it practical, beginner-friendly, and concise.
    PROMPT

    [base_prompt, context_prompt, format_prompt].join("\n\n")
  end

  def extract_text(parsed_response)
    parts = parsed_response.dig("candidates", 0, "content", "parts")
    return "" unless parts.is_a?(Array)

    parts.map { |part| part["text"] }.compact.join("\n").strip
  end

  def parse_sections(text)
    normalised_text = text.gsub(/\r\n?/, "\n")

    {
      overview: extract_section(normalised_text, "OVERVIEW:", "STEPS:"),
      steps: extract_section(normalised_text, "STEPS:", "CODE EXAMPLE:"),
      code_example: extract_section(normalised_text, "CODE EXAMPLE:", "DOC LINK:"),
      doc_link: extract_section(normalised_text, "DOC LINK:", "TAGS:"),
      tags: extract_section(normalised_text, "TAGS:", nil)
    }
  end

  def extract_section(text, start_marker, end_marker)
    start_index = text.index(start_marker)
    return "" unless start_index

    start_index += start_marker.length

    if end_marker
      end_index = text.index(end_marker, start_index)
      return text[start_index...end_index].to_s.strip
    end

    text[start_index..].to_s.strip
  end
end