class AddDeactivatedBySyncToCryptics < ActiveRecord::Migration[8.1]
  def change
    add_column :cryptics, :deactivated_by_sync, :boolean, null: false, default: false
  end
end