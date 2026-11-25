class AddRoleAndActiveToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "score_editor"
    add_column :users, :active, :boolean, null: false, default: true
    add_check_constraint :users, "role IS NOT NULL AND role IN ('admin', 'score_editor')", name: "users_role_allowed"

    # Los usuarios creados antes de esta migración eran administradores.
    up_only { execute "UPDATE users SET role = 'admin'" }
  end
end
