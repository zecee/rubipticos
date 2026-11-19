class CreateCryptics < ActiveRecord::Migration[8.1]
  def change
    create_table :cryptics do |t|
      t.string :external_id, null: false

      t.text :clue, null: false
      t.string :answer, null: false

      t.json :definitions, null: false, default: []
      t.json :indicators, null: false, default: []
      t.json :material, null: false, default: []

      t.string :puzzle_type, null: false
      t.string :difficulty, null: false

      t.text :hint
      t.text :explanation
      t.string :author
      t.string :source, null: false

      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :cryptics, :external_id, unique: true
  end
end
