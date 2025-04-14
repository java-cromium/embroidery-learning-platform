class CreateAdminFilterPresets < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_filter_presets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :resource_type, null: false
      t.json :filters, null: false
      t.boolean :global, default: false
      t.text :description
      t.integer :usage_count, default: 0
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :admin_filter_presets, [:user_id, :resource_type, :name], unique: true, name: 'idx_admin_filter_presets_composite'
    add_index :admin_filter_presets, [:resource_type, :global]
  end
end
