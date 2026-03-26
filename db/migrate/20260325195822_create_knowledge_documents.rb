class CreateKnowledgeDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :knowledge_documents do |t|
      t.string :title
      t.string :technology
      t.string :source_name
      t.string :source_type
      t.text :raw_content

      t.timestamps
    end
  end
end
