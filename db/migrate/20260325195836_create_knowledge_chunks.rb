class CreateKnowledgeChunks < ActiveRecord::Migration[7.2]
  def change
    create_table :knowledge_chunks do |t|
      t.references :knowledge_document, null: false, foreign_key: true
      t.text :content
      t.integer :position

      t.timestamps
    end
  end
end
