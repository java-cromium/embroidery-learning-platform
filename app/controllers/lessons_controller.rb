class App < Sinatra::Base
  # Lesson viewing
  get '/courses/:course_id/lessons/:id' do
    @course = Course.find(params[:course_id])
    @lesson = @course.lessons.find(params[:id])
    
    unless @lesson.accessible_by?(current_user)
      flash[:error] = "This is a premium lesson. Please upgrade to access."
      redirect '/pricing'
    end

    @progress = current_user ? @lesson.progress_for(current_user) : nil
    erb :'lessons/show'
  end

  # Update lesson progress
  post '/lessons/:id/progress' do
    require_authentication
    
    lesson = Lesson.find(params[:id])
    percentage = params[:progress_percentage].to_f
    watch_time = params[:watch_time].to_i

    progress = lesson.user_progress.find_or_initialize_by(user: current_user)
    progress.progress_percentage = percentage
    progress.watch_time_seconds = watch_time
    progress.last_watched_at = Time.current
    
    if progress.save
      json success: true, completed: progress.completed?
    else
      status 422
      json error: progress.errors.full_messages
    end
  end

  # Admin routes for lesson management
  get '/admin/courses/:course_id/lessons/new' do
    require_admin
    @course = Course.find(params[:course_id])
    @lesson = @course.lessons.new
    erb :'admin/lessons/new'
  end

  post '/admin/courses/:course_id/lessons' do
    require_admin
    @course = Course.find(params[:course_id])
    @lesson = @course.lessons.new(params[:lesson])

    if @lesson.save
      flash[:success] = "Lesson created successfully"
      redirect "/admin/courses/#{@course.id}/lessons/#{@lesson.id}/edit"
    else
      flash[:error] = @lesson.errors.full_messages.join(", ")
      erb :'admin/lessons/new'
    end
  end

  get '/admin/courses/:course_id/lessons/:id/edit' do
    require_admin
    @course = Course.find(params[:course_id])
    @lesson = @course.lessons.find(params[:id])
    erb :'admin/lessons/edit'
  end

  put '/admin/courses/:course_id/lessons/:id' do
    require_admin
    @course = Course.find(params[:course_id])
    @lesson = @course.lessons.find(params[:id])

    if @lesson.update(params[:lesson])
      flash[:success] = "Lesson updated successfully"
      redirect "/admin/courses/#{@course.id}/lessons/#{@lesson.id}/edit"
    else
      flash[:error] = @lesson.errors.full_messages.join(", ")
      erb :'admin/lessons/edit'
    end
  end

  delete '/admin/courses/:course_id/lessons/:id' do
    require_admin
    course = Course.find(params[:course_id])
    lesson = course.lessons.find(params[:id])
    lesson.destroy
    flash[:success] = "Lesson deleted successfully"
    redirect "/admin/courses/#{course.id}/edit"
  end

  # Lesson position management
  post '/admin/lessons/:id/move/:direction' do
    require_admin
    lesson = Lesson.find(params[:id])
    other_lesson = case params[:direction]
                  when 'up'
                    lesson.course.lessons.where('position < ?', lesson.position).last
                  when 'down'
                    lesson.course.lessons.where('position > ?', lesson.position).first
                  end

    if other_lesson
      old_position = lesson.position
      lesson.update(position: other_lesson.position)
      other_lesson.update(position: old_position)
    end

    redirect "/admin/courses/#{lesson.course_id}/edit"
  end
end
