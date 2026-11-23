class CreateSyncRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_runs do |t|
      t.references :user, foreign_key: true # null when run from db:seed

      t.string :source_url, null: false
      t.string :status, null: false
      t.string :version

      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.integer :deactivated_count, null: false, default: 0
      t.integer :rejected_count, null: false, default: 0

      t.json :rejections, null: false, default: []
      t.text :error_message

      t.timestamps
    end

    add_index :sync_runs, %i[status source_url]
  end
end
