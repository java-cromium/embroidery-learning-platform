class FacebookService
  def initialize(user)
    @user = user
    @client = Koala::Facebook::API.new(@user.social_profiles.dig('facebook', 'access_token'))
  end

  def fetch_recent_posts
    posts = @client.get_connections('me', 'posts', {
      fields: ['id', 'message', 'created_time', 'type', 'permalink_url', 'attachments']
    })

    posts.each do |post|
      begin
        SocialMediaPost.create_from_facebook(post, @user)
      rescue ActiveRecord::RecordNotUnique
        next # Skip if already exists
      end
    end
  end

  def refresh_token
    oauth = Koala::Facebook::OAuth.new(
      ENV['FACEBOOK_APP_ID'],
      ENV['FACEBOOK_APP_SECRET']
    )

    new_token = oauth.exchange_access_token_info(
      @user.social_profiles.dig('facebook', 'access_token')
    )

    if new_token['access_token']
      @user.update_social_profile('facebook', {
        access_token: new_token['access_token'],
        token_refreshed_at: Time.current
      })
    end
  end
end
