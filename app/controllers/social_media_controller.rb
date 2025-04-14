class App < Sinatra::Base
  # Social Media Gallery
  get '/gallery' do
    @posts = SocialMediaPost.recent.limit(50)
    erb :'social_media/gallery'
  end

  # OAuth Callbacks
  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    
    if current_user
      case params[:provider]
      when 'instagram'
        current_user.update_social_profile('instagram', {
          'username' => auth.info.nickname,
          'access_token' => auth.credentials.token,
          'token_refreshed_at' => Time.current
        })
      when 'facebook'
        current_user.update_social_profile('facebook', {
          'username' => auth.info.nickname,
          'access_token' => auth.credentials.token,
          'token_refreshed_at' => Time.current
        })
      when 'twitter'
        current_user.update_social_profile('twitter', {
          'username' => auth.info.nickname,
          'access_token' => auth.credentials.token,
          'access_token_secret' => auth.credentials.secret
        })
      when 'tiktok'
        current_user.update_social_profile('tiktok', {
          'username' => auth.info.nickname,
          'access_token' => auth.credentials.token,
          'refresh_token' => auth.credentials.refresh_token,
          'token_refreshed_at' => Time.current
        })
      end

      # Trigger initial sync
      SocialMediaSyncWorker.perform_async(current_user.id)
      
      flash[:success] = "Successfully connected #{params[:provider].titleize}"
      redirect '/profile'
    else
      flash[:error] = "Please log in first"
      redirect '/login'
    end
  end

  # Disconnect social media
  post '/social/:provider/disconnect' do
    provider = params[:provider]
    if current_user && current_user.social_profiles[provider]
      profiles = current_user.social_profiles
      profiles.delete(provider)
      current_user.update(social_profiles: profiles)
      flash[:success] = "Successfully disconnected #{provider.titleize}"
    end
    redirect '/profile'
  end
end
