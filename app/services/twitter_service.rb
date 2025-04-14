class TwitterService
  def initialize(user)
    @user = user
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_API_KEY']
      config.consumer_secret = ENV['TWITTER_API_SECRET']
      config.access_token = @user.social_profiles.dig('twitter', 'access_token')
      config.access_token_secret = @user.social_profiles.dig('twitter', 'access_token_secret')
    end
  end

  def fetch_recent_tweets
    tweets = @client.user_timeline(
      @user.social_profiles.dig('twitter', 'username'),
      count: 50,
      include_rts: false,
      exclude_replies: true,
      tweet_mode: 'extended'
    )

    tweets.each do |tweet|
      begin
        SocialMediaPost.create_from_twitter(tweet, @user)
      rescue ActiveRecord::RecordNotUnique
        next # Skip if already exists
      end
    end
  end
end
