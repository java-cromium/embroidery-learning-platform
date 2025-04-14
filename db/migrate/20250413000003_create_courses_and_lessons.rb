class CreateCoursesAndLessons < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :title, null: false
      t.text :description
      t.string :difficulty_level
      t.string :category
      t.string :thumbnail_url
      t.boolean :premium, default: false
      t.integer :position
      t.timestamps
    end

    create_table :lessons do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :video_url
      t.string :thumbnail_url
      t.integer :duration_seconds
      t.integer :position
      t.boolean :premium, default: false
      t.jsonb :materials, default: {}
      t.timestamps
    end

    create_table :user_progress do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.float :progress_percentage, default: 0
      t.boolean :completed, default: false
      t.datetime :last_watched_at
      t.integer :watch_time_seconds, default: 0
      t.timestamps
    end

    add_index :courses, :premium
    add_index :lessons, :premium
    add_index :lessons, [:course_id, :position]
    add_index :user_progress, [:user_id, :lesson_id], unique: true
  end
end
