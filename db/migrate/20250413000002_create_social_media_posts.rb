class CreateSocialMediaPosts < ActiveRecord::Migration[7.0]
  def change
    create_table :social_media_posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :external_id, null: false
      t.string :content_type
      t.string :media_url
      t.string :thumbnail_url
      t.text :caption
      t.string :permalink
      t.datetime :posted_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :social_media_posts, [:platform, :external_id], unique: true
    add_index :social_media_posts, :posted_at
  end
end
