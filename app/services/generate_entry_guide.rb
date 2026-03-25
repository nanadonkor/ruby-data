class GenerateEntryGuide
  def initialize(entry)
    @entry = entry
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def call
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    parsed_content = parse_content(content)

    @entry.update!(
      overview: parsed_content[:overview],
      steps: parsed_content[:steps],
      code_example: parsed_content[:code_example],
      doc_link: parsed_content[:doc_link],
      tags: parsed_content[:tags]
    )
  end

  private

  def system_prompt
    <<~PROMPT
      You are a practical technical learning assistant.
      You explain how to use a technology for a specific use case.
      Keep explanations beginner-friendly, practical, and concise.
      Return the answer in exactly the requested format.
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      A user wants to learn:

      Technology: #{@entry.technology}
      Use case: #{@entry.use_case}

      Return the answer in exactly this structure:

      OVERVIEW:
      A short explanation of how this technology is used for this use case.

      STEPS:
      1. First step
      2. Second step
      3. Third step

      CODE_EXAMPLE:
      A simple code example only.

      DOC_LINK:
      One official documentation link if possible.

      TAGS:
      comma-separated tags
    PROMPT
  end

  def parse_content(content)
    {
      overview: extract_section(content, "OVERVIEW"),
      steps: extract_section(content, "STEPS"),
      code_example: extract_section(content, "CODE_EXAMPLE"),
      doc_link: extract_section(content, "DOC_LINK"),
      tags: extract_section(content, "TAGS")
    }
  end

  def extract_section(content, section_name)
    match = content.match(/#{section_name}:\s*(.*?)(?=\n[A-Z_]+:|\z)/m)
    return "" unless match

    match[1].strip
  end
end
