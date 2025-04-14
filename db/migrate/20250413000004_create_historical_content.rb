class CreateHistoricalContent < ActiveRecord::Migration[7.0]
  def change
    create_table :historical_periods do |t|
      t.string :name, null: false
      t.text :description
      t.string :era
      t.integer :start_year
      t.integer :end_year
      t.string :region
      t.string :image_url
      t.integer :position
      t.timestamps
    end

    create_table :historical_artifacts do |t|
      t.references :historical_period, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :location
      t.string :image_url
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    create_table :embroidery_techniques do |t|
      t.string :name, null: false
      t.text :description
      t.string :origin
      t.text :instructions
      t.string :difficulty_level
      t.string :image_url
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :historical_periods, :position
    add_index :historical_periods, :era
    add_index :historical_periods, :region
  end
end
