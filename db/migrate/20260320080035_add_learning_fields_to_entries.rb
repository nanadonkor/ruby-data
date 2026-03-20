class AddLearningFieldsToEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :technology, :string
    add_column :entries, :use_case, :string
    add_column :entries, :overview, :text
    add_column :entries, :steps, :text
    add_column :entries, :code_example, :text
    add_column :entries, :doc_link, :string
    add_column :entries, :tags, :string
  end
end
