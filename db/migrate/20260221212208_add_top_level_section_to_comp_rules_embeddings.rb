class AddTopLevelSectionToCompRulesEmbeddings < ActiveRecord::Migration[8.1]
  def change
    add_column :comp_rules_embeddings, :top_level_section, :string
    add_index :comp_rules_embeddings, :top_level_section
  end
end
