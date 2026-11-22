class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.string :name_key, null: false
      t.string :token_digest, null: false
      t.timestamps
    end

    add_index :players, :name_key, unique: true
    add_index :players, :token_digest, unique: true
  end
end
