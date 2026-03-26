class RetrieveKnowledgeContext
  def initialize(technology:, use_case:)
    @technology = technology.to_s.strip
    @use_case = use_case.to_s.strip
  end

  def call
    return [] if search_terms.empty?

    KnowledgeChunk
      .joins(:knowledge_document)
      .where(search_sql, *search_values)
      .order(position: :asc)
      .limit(5)
  end

  private

  def search_terms
    [@technology, @use_case].reject(&:empty?)
  end

  def search_sql
    search_terms.map { "knowledge_chunks.content ILIKE ?" }.join(" OR ")
  end

  def search_values
    search_terms.map { |term| "%#{term}%" }
  end
end