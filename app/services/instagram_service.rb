require 'koala'
require 'json'

class InstagramService
  FIELDS = 'id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username'

  def initialize
    @graph = Koala::Facebook::API.new(ENV['INSTAGRAM_ACCESS_TOKEN'])
  end

  def fetch_recent_media(limit = 12)
    begin
      # Get media from the Instagram Graph API
      media = @graph.get_connection(
        ENV['INSTAGRAM_BUSINESS_ACCOUNT_ID'],
        'media',
        fields: FIELDS,
        limit: limit
      )

      # Transform the data into a more usable format
      media.map do |post|
        {
          id: post['id'],
          caption: post['caption'],
          media_type: post['media_type'],
          media_url: post['media_url'],
          permalink: post['permalink'],
          thumbnail_url: post['thumbnail_url'] || post['media_url'],
          timestamp: post['timestamp'],
          username: post['username']
        }
      end
    rescue Koala::Facebook::APIError => e
      puts "Instagram API Error: #{e.message}"
      []
    end
  end

  def refresh_token
    begin
      oauth = Koala::Facebook::OAuth.new(
        ENV['FACEBOOK_APP_ID'],
        ENV['FACEBOOK_APP_SECRET']
      )
      
      new_token = oauth.exchange_access_token(ENV['INSTAGRAM_ACCESS_TOKEN'])
      # You would typically save this new token to your environment variables
      # or a secure configuration system
      puts "New token generated. Update your INSTAGRAM_ACCESS_TOKEN with: #{new_token}"
      new_token
    rescue => e
      puts "Token refresh error: #{e.message}"
      nil
    end
  end

  private

  def handle_api_error(error)
    case error
    when Koala::Facebook::AuthenticationError
      puts "Authentication error: Token may be invalid or expired"
    when Koala::Facebook::ClientError
      puts "Client error: #{error.message}"
    when Koala::Facebook::ServerError
      puts "Instagram API is having issues: #{error.message}"
    else
      puts "Unknown error: #{error.message}"
    end
    []
  end
end
