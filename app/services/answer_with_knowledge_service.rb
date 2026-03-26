class AnswerWithKnowledgeService
  def initialize(question)
    @question = question
  end

  def call
    chunks = retrieve_relevant_chunks

    prompt = build_prompt(chunks)

    response = call_llm(prompt)

    response
  end

  private

  def retrieve_relevant_chunks
    # simple version first (we improve later)
    KnowledgeChunk
      .where("content ILIKE ?", "%#{@question}%")
      .limit(5)
  end

  def build_prompt(chunks)
    context = chunks.map(&:content).join("\n\n")

    <<~PROMPT
      Use the following context to answer the question.

      Context:
      #{context}

      Question:
      #{@question}

      Answer clearly and practically.
    PROMPT
  end

  def call_llm(prompt)
    # for now just return prompt (we plug API next)
    prompt
  end
end