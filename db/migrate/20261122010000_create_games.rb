class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :player, null: false, foreign_key: true
      t.references :cryptic, null: false, foreign_key: true
      t.string :status, null: false, default: "PREPARED"
      t.datetime :started_at
      t.datetime :solved_at
      t.timestamps
    end

    add_index :games, [ :player_id, :cryptic_id ], unique: true
    add_index :games, :player_id, unique: true,
      where: "status IN ('PREPARED', 'IN_PROGRESS')", name: "index_games_on_pending_player"
  end
end
