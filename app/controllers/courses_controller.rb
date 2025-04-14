class App < Sinatra::Base
  # Course listing
  get '/courses' do
    @courses = Course.ordered
    erb :'courses/index'
  end

  # Course details
  get '/courses/:id' do
    @course = Course.find(params[:id])
    
    unless @course.accessible_by?(current_user)
      flash[:error] = "This is a premium course. Please upgrade to access."
      redirect '/pricing'
    end

    @user_progress = current_user ? @course.completion_percentage(current_user) : 0
    @lessons = @course.lessons.ordered
    erb :'courses/show'
  end

  # Admin authentication helper
  def require_admin
    require_authentication
    halt 403 unless current_user.admin?
  end

  # Admin routes for course management
  before '/admin/*' do
    require_admin
  end

  get '/admin/courses/new' do
    @course = Course.new
    erb :'admin/courses/new'
  end

  post '/admin/courses' do
    @course = Course.new(params[:course])
    if @course.save
      flash[:success] = "Course created successfully"
      redirect "/admin/courses/#{@course.id}/edit"
    else
      flash[:error] = @course.errors.full_messages.join(", ")
      erb :'admin/courses/new'
    end
  end

  get '/admin/courses/:id/edit' do
    @course = Course.find(params[:id])
    erb :'admin/courses/edit'
  end

  put '/admin/courses/:id' do
    @course = Course.find(params[:id])
    if @course.update(params[:course])
      flash[:success] = "Course updated successfully"
      redirect "/admin/courses/#{@course.id}/edit"
    else
      flash[:error] = @course.errors.full_messages.join(", ")
      erb :'admin/courses/edit'
    end
  end

  delete '/admin/courses/:id' do
    course = Course.find(params[:id])
    course.destroy
    flash[:success] = "Course deleted successfully"
    redirect '/admin/courses'
  end

  # Course position management
  post '/admin/courses/:id/move/:direction' do
    course = Course.find(params[:id])
    other_course = case params[:direction]
                  when 'up'
                    Course.where('position < ?', course.position).last
                  when 'down'
                    Course.where('position > ?', course.position).first
                  end

    if other_course
      old_position = course.position
      course.update(position: other_course.position)
      other_course.update(position: old_position)
    end

    redirect '/admin/courses'
  end
end
