class TikTokService
  def initialize(user)
    @user = user
    @access_token = @user.social_profiles.dig('tiktok', 'access_token')
  end

  def fetch_recent_videos
    response = HTTParty.get(
      'https://open.tiktokapis.com/v2/video/list/',
      headers: {
        'Authorization': "Bearer #{@access_token}",
        'Content-Type': 'application/json'
      },
      query: {
        max_count: 20
      }
    )

    if response.success?
      response['data']['videos'].each do |video|
        begin
          SocialMediaPost.create_from_tiktok(video, @user)
        rescue ActiveRecord::RecordNotUnique
          next # Skip if already exists
        end
      end
    end
  end

  def refresh_token
    response = HTTParty.post(
      'https://open-api.tiktok.com/oauth/refresh_token/',
      query: {
        client_key: ENV['TIKTOK_CLIENT_KEY'],
        grant_type: 'refresh_token',
        refresh_token: @user.social_profiles.dig('tiktok', 'refresh_token')
      }
    )

    if response.success?
      @user.update_social_profile('tiktok', {
        access_token: response['access_token'],
        refresh_token: response['refresh_token'],
        token_refreshed_at: Time.current
      })
    end
  end
end
