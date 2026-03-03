class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.text :text, null: false
      t.string :confidence, null: false
      t.text :answer
      t.text :message
      t.jsonb :sources, null: false, default: []

      t.timestamps
    end
  end
end
