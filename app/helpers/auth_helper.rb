module AuthHelper
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
  end

  def authenticated?
    !current_user.nil?
  end

  def require_authentication
    unless authenticated?
      session[:return_to] = request.path
      flash[:error] = "Please log in to access this page"
      redirect '/login'
    end
  end

  def require_no_authentication
    if authenticated?
      flash[:notice] = "You are already logged in"
      redirect '/'
    end
  end

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end

  def verify_jwt_token(token)
    JWT.decode(token, ENV['JWT_SECRET'], true, algorithm: 'HS256')[0]
  rescue JWT::DecodeError
    nil
  end
end
