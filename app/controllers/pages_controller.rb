class App < Sinatra::Base
  # Home page
  get '/' do
    erb :index
  end

  # About Us page
  get '/about' do
    erb :about
  end

  # Embroidery History page
  get '/history' do
    erb :history
  end

  # Social Media Gallery
  get '/gallery' do
    @social_posts = SocialMediaFeed.recent
    erb :gallery
  end
end
