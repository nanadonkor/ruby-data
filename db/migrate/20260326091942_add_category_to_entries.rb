class AddCategoryToEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :category, :string
  end
end
