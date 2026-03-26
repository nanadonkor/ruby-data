class ChunkKnowledgeDocument
  def initialize(knowledge_document)
    @knowledge_document = knowledge_document
  end

  def call
    @knowledge_document.knowledge_chunks.destroy_all

    chunks.each_with_index do |chunk, index|
      @knowledge_document.knowledge_chunks.create!(
        content: chunk,
        position: index
      )
    end
  end

  private

  def chunks
    @knowledge_document.raw_content
                       .split(/\n\s*\n/)
                       .map(&:strip)
                       .reject(&:empty?)
  end
end