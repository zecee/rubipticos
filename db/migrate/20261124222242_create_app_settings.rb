class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings do |t|
      t.string :source_url, null: false
      t.text :welcome_text, null: false
      t.datetime :leaderboard_reset_at # null: nunca se reinició

      t.timestamps

      t.check_constraint "id = 1", name: "app_settings_singleton"
    end
  end
end