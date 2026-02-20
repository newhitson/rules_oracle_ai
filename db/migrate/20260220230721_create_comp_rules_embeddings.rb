class CreateCompRulesEmbeddings < ActiveRecord::Migration[8.1]
  def change
    create_table :comp_rules_embeddings do |t|
      t.string :section_number, null: false
      t.string :title
      t.text :content, null: false
      t.vector :embedding, limit: 1536
      t.timestamps
    end

    add_index :comp_rules_embeddings, :section_number, unique: true

    add_index :comp_rules_embeddings, :embedding,
              using: :hnsw,
              opclass: :vector_cosine_ops
  end
end
