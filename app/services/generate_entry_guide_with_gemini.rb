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

  def prompt
    <<~PROMPT
      You are helping a developer learn a technology for a specific use case.

      Technology: #{@entry.technology}
      Use case: #{@entry.use_case}

      Return the response in exactly this format:

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

      Keep it practical, beginner-friendly, and concise.
    PROMPT
  end

  def extract_text(parsed_response)
    parsed_response
      .dig("candidates", 0, "content", "parts", 0, "text")
      .to_s
      .strip
  end

  def parse_sections(text)
    {
      overview: extract_section(text, "OVERVIEW:", "STEPS:"),
      steps: extract_section(text, "STEPS:", "CODE EXAMPLE:"),
      code_example: extract_section(text, "CODE EXAMPLE:", "DOC LINK:"),
      doc_link: extract_section(text, "DOC LINK:", "TAGS:"),
      tags: extract_section(text, "TAGS:", nil)
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
