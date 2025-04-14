class CreateAdminRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_roles do |t|
      t.string :name, null: false
      t.string :description
      t.jsonb :permissions, null: false, default: {}
      t.boolean :is_system_role, null: false, default: false
      t.timestamps
    end

    add_index :admin_roles, :name, unique: true

    create_table :admin_role_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :admin_role, null: false, foreign_key: true
      t.timestamps
    end

    add_index :admin_role_assignments, [:user_id, :admin_role_id], unique: true
  end
end
