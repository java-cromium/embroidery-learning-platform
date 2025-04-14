class SocialMediaPost < ActiveRecord::Base
  belongs_to :user

  validates :platform, presence: true, inclusion: { in: %w[instagram facebook twitter tiktok] }
  validates :external_id, presence: true, uniqueness: { scope: :platform }
  validates :content_type, presence: true
  validates :posted_at, presence: true

  scope :recent, -> { order(posted_at: :desc) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  
  def self.create_from_instagram(data, user)
    create!(
      user: user,
      platform: 'instagram',
      external_id: data['id'],
      content_type: data['media_type'],
      media_url: data['media_url'],
      thumbnail_url: data['thumbnail_url'],
      caption: data['caption'],
      permalink: data['permalink'],
      posted_at: Time.parse(data['timestamp']),
      metadata: data
    )
  end

  def self.create_from_facebook(data, user)
    create!(
      user: user,
      platform: 'facebook',
      external_id: data['id'],
      content_type: data['type'],
      media_url: data.dig('attachments', 'data', 0, 'media', 'image', 'src'),
      caption: data['message'],
      permalink: data['permalink_url'],
      posted_at: Time.parse(data['created_time']),
      metadata: data
    )
  end

  def self.create_from_twitter(tweet, user)
    media_url = tweet.media? ? tweet.media[0].url.to_s : nil
    create!(
      user: user,
      platform: 'twitter',
      external_id: tweet.id,
      content_type: tweet.media? ? tweet.media[0].type : 'text',
      media_url: media_url,
      caption: tweet.text,
      permalink: tweet.url.to_s,
      posted_at: tweet.created_at,
      metadata: tweet.to_h
    )
  end

  def self.create_from_tiktok(data, user)
    create!(
      user: user,
      platform: 'tiktok',
      external_id: data['id'],
      content_type: 'video',
      media_url: data['video']['play_addr']['url_list'].first,
      thumbnail_url: data['video']['cover']['url_list'].first,
      caption: data['desc'],
      permalink: "https://www.tiktok.com/@#{data['author']['unique_id']}/video/#{data['id']}",
      posted_at: Time.at(data['create_time']),
      metadata: data
    )
  end
end
