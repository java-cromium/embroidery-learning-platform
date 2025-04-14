require 'sinatra'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/partial'
require 'erubis'
require 'dotenv/load'
require 'jwt'
require 'omniauth'
require 'sidekiq'
require 'shrine'
require 'money'
require 'bcrypt'
require_relative 'config/initializers/shrine'

# Load application record first
require_relative 'app/models/application_record'

# Load all other models, helpers, and routes
Dir["./app/models/*.rb"].reject { |f| f.end_with?('application_record.rb') }.each { |file| require file }
Dir["./app/helpers/*.rb"].each { |file| require file }
Dir["./app/workers/*.rb"].each { |file| require file }

class App < Sinatra::Base
  # Register extensions
  register Sinatra::Namespace

  # Configuration
  configure do
    set :root, File.dirname(__FILE__)
    set :public_folder, 'public'
    set :views, 'app/views'
    enable :sessions
    set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    set :database_file, 'config/database.yml'
    set :erb, layout: :'layout.html'
    set :partial_template_engine, :erb
    enable :partial_underscores
    register Sinatra::Partial
  end

  helpers do
    def h(text)
      Rack::Utils.escape_html(text)
    end

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end

    def logged_in?
      !current_user.nil?
    end

    def admin?
      logged_in? && current_user.admin?
    end

    def require_login
      unless logged_in?
        session[:return_to] = request.path
        redirect '/login'
      end
    end

    def require_admin
      unless admin?
        session[:return_to] = request.path
        redirect '/login'
      end
    end

    def current_page?(path)
      request.path_info == path
    end

    def require_authentication
      halt 401 unless current_user
    end
  end

  # Middleware
  use Rack::Session::Cookie, 
    key: 'embroidery.session',
    secret: ENV['SESSION_SECRET']

  # OmniAuth Configuration will be added later

  # Routes
  get '/' do
    erb :'index.html', layout: :'layout.html'
  end

  get '/gallery' do
    instagram = InstagramService.new
    @instagram_posts = instagram.fetch_recent_media
    erb :'gallery.html', layout: :'layout.html'
  end

  get '/about' do
    erb :'about.html', layout: :'layout.html'
  end

  get '/history' do
    erb :'history.html', layout: :'layout.html'
  end

  get '/gallery' do
    erb :'gallery.html', layout: :'layout.html'
  end

  get '/courses' do
    erb :'courses.html', layout: :'layout.html'
  end

  get '/signup' do
    erb :'signup.html', layout: :'layout.html'
  end

  post '/signup' do
    user = User.new(
      username: params[:username],
      email: params[:email],
      password: params[:password],
      subscription_tier: 'free',
      admin: false
    )

    if user.save
      session[:user_id] = user.id
      redirect '/'
    else
      @errors = user.errors.full_messages
      erb :'signup.html', layout: :'layout.html'
    end
  end

  get '/login' do
    erb :'login.html', layout: :'layout.html'
  end

  post '/login' do
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect '/'
    else
      @error = 'Invalid email or password'
      erb :'login.html', layout: :'layout.html'
    end
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  # Error Handling
  not_found do
    erb :'errors/404'
  end

  error do
    erb :'errors/500'
  end
end
