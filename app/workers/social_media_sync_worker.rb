class SocialMediaSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :social_media, retry: 3

  def perform(user_id)
    user = User.find(user_id)
    
    # Sync Instagram
    if user.social_profiles['instagram']
      service = InstagramService.new(user)
      service.fetch_recent_media
      service.refresh_token if token_needs_refresh?('instagram', user)
    end

    # Sync Facebook
    if user.social_profiles['facebook']
      service = FacebookService.new(user)
      service.fetch_recent_posts
      service.refresh_token if token_needs_refresh?('facebook', user)
    end

    # Sync Twitter
    if user.social_profiles['twitter']
      TwitterService.new(user).fetch_recent_tweets
    end

    # Sync TikTok
    if user.social_profiles['tiktok']
      service = TikTokService.new(user)
      service.fetch_recent_videos
      service.refresh_token if token_needs_refresh?('tiktok', user)
    end
  end

  private

  def token_needs_refresh?(platform, user)
    last_refresh = user.social_profiles.dig(platform, 'token_refreshed_at')
    return true unless last_refresh

    case platform
    when 'instagram'
      Time.parse(last_refresh) < 30.days.ago
    when 'facebook'
      Time.parse(last_refresh) < 55.days.ago
    when 'tiktok'
      Time.parse(last_refresh) < 15.days.ago
    else
      false
    end
  end
end
