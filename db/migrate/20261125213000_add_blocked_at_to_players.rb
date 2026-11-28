class AddBlockedAtToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :blocked_at, :datetime # null: no está bloqueado
  end
end
