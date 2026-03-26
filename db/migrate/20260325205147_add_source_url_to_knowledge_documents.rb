class AddSourceUrlToKnowledgeDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :knowledge_documents, :source_url, :string
  end
end
