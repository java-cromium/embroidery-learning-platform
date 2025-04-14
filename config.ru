require './app'
require 'sidekiq/web'

# Protect Sidekiq dashboard in production
map '/sidekiq' do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    # TODO: Replace with secure authentication
    username == ENV['ADMIN_USERNAME'] && password == ENV['ADMIN_PASSWORD']
  end

  run Sidekiq::Web
end

run App
