class KnowledgeDocumentsController < ApplicationController
  def index
    @knowledge_documents = KnowledgeDocument.order(created_at: :desc)
  end

  def new
    @knowledge_document = KnowledgeDocument.new
  end

  def create
    @knowledge_document = KnowledgeDocument.new(knowledge_document_params)

    if @knowledge_document.save
      ChunkKnowledgeDocument.new(@knowledge_document).call
      redirect_to root_path, notice: "Knowledge document uploaded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def knowledge_document_params
  params.require(:knowledge_document).permit(
    :title,
    :technology,
    :source_name,
    :source_type,
    :source_url,
    :raw_content
  )
  end
end