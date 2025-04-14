class App < Sinatra::Base
  helpers AuthHelper

  # Sign Up
  get '/signup' do
    require_no_authentication
    erb :'auth/signup'
  end

  post '/signup' do
    require_no_authentication
    
    @user = User.new(
      email: params[:email],
      username: params[:username],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      first_name: params[:first_name],
      last_name: params[:last_name]
    )

    if @user.save
      session[:user_id] = @user.id
      flash[:success] = "Welcome to Embroidery Learning Platform!"
      redirect '/'
    else
      flash[:error] = @user.errors.full_messages.join(", ")
      erb :'auth/signup'
    end
  end

  # Login
  get '/login' do
    require_no_authentication
    erb :'auth/login'
  end

  post '/login' do
    require_no_authentication
    
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:success] = "Welcome back, #{user.first_name}!"
      redirect session.delete(:return_to) || '/'
    else
      flash[:error] = "Invalid email or password"
      erb :'auth/login'
    end
  end

  # Logout
  get '/logout' do
    session.clear
    flash[:notice] = "You have been logged out"
    redirect '/'
  end

  # Password Reset
  get '/forgot-password' do
    require_no_authentication
    erb :'auth/forgot_password'
  end

  post '/forgot-password' do
    require_no_authentication
    
    user = User.find_by(email: params[:email])
    if user
      token = generate_jwt_token(user)
      # TODO: Send password reset email
      flash[:success] = "Password reset instructions have been sent to your email"
    else
      flash[:error] = "Email not found"
    end
    redirect '/login'
  end

  get '/reset-password/:token' do
    require_no_authentication
    
    payload = verify_jwt_token(params[:token])
    if payload && (@user = User.find_by(id: payload['user_id']))
      erb :'auth/reset_password'
    else
      flash[:error] = "Invalid or expired reset token"
      redirect '/login'
    end
  end

  post '/reset-password/:token' do
    require_no_authentication
    
    payload = verify_jwt_token(params[:token])
    if payload && (@user = User.find_by(id: payload['user_id']))
      if params[:password] == params[:password_confirmation]
        @user.update(password: params[:password])
        flash[:success] = "Password has been reset successfully"
        redirect '/login'
      else
        flash[:error] = "Passwords don't match"
        erb :'auth/reset_password'
      end
    else
      flash[:error] = "Invalid or expired reset token"
      redirect '/login'
    end
  end

  # Profile Management
  get '/profile' do
    require_authentication
    erb :'auth/profile'
  end

  put '/profile' do
    require_authentication
    
    if current_user.update(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email],
      username: params[:username]
    )
      flash[:success] = "Profile updated successfully"
    else
      flash[:error] = current_user.errors.full_messages.join(", ")
    end
    redirect '/profile'
  end

  # Change Password
  get '/change-password' do
    require_authentication
    erb :'auth/change_password'
  end

  post '/change-password' do
    require_authentication
    
    if current_user.authenticate(params[:current_password])
      if params[:new_password] == params[:new_password_confirmation]
        if current_user.update(password: params[:new_password])
          flash[:success] = "Password changed successfully"
          redirect '/profile'
        else
          flash[:error] = current_user.errors.full_messages.join(", ")
        end
      else
        flash[:error] = "New passwords don't match"
      end
    else
      flash[:error] = "Current password is incorrect"
    end
    erb :'auth/change_password'
  end
end
