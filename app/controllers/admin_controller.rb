class App < Sinatra::Base
  before '/admin/*' do
    require_admin
  end

  # Admin Dashboard
  get '/admin' do
    @page_title = 'Dashboard'
    @total_users = User.count
    @total_subscriptions = Subscription.active.count
    @total_revenue = Subscription.active.joins(:subscription_plan)
                               .sum('subscription_plans.price_cents') / 100.0
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_subscriptions = Subscription.order(created_at: :desc).limit(5)
    
    erb :'admin/dashboard', layout: :'layouts/admin'
  end

  # Users Management
  get '/admin/users' do
    @page_title = 'Users'
    @users = User.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
    erb :'admin/users/index', layout: :'layouts/admin'
  end

  get '/admin/users/:id' do
    @user = User.find(params[:id])
    @page_title = "User: #{@user.email}"
    erb :'admin/users/show', layout: :'layouts/admin'
  end

  post '/admin/users/:id/toggle_admin' do
    user = User.find(params[:id])
    user.update(admin: !user.admin)
    flash[:success] = "Admin status updated for #{user.email}"
    redirect "/admin/users/#{user.id}"
  end

  # Subscription Plans Management
  get '/admin/subscriptions' do
    @page_title = 'Subscription Plans'
    @plans = SubscriptionPlan.order(price_cents: :asc)
    @active_subscriptions = Subscription.active.includes(:user, :subscription_plan)
                                     .order(created_at: :desc)
                                     .paginate(page: params[:page], per_page: 20)
    erb :'admin/subscriptions/index', layout: :'layouts/admin'
  end

  get '/admin/subscriptions/plans/new' do
    @page_title = 'New Subscription Plan'
    @plan = SubscriptionPlan.new
    erb :'admin/subscriptions/plans/new', layout: :'layouts/admin'
  end

  post '/admin/subscriptions/plans' do
    @plan = SubscriptionPlan.new(
      name: params[:name],
      price_cents: (params[:price].to_f * 100).to_i,
      billing_interval: params[:billing_interval],
      features: { included: params[:features].split("\n").map(&:strip) },
      stripe_price_id: params[:stripe_price_id],
      active: params[:active] == 'true'
    )

    if @plan.save
      flash[:success] = 'Subscription plan created successfully'
      redirect '/admin/subscriptions'
    else
      flash[:error] = @plan.errors.full_messages.join(', ')
      erb :'admin/subscriptions/plans/new', layout: :'layouts/admin'
    end
  end

  get '/admin/subscriptions/plans/:id/edit' do
    @plan = SubscriptionPlan.find(params[:id])
    @page_title = "Edit #{@plan.name}"
    erb :'admin/subscriptions/plans/edit', layout: :'layouts/admin'
  end

  patch '/admin/subscriptions/plans/:id' do
    @plan = SubscriptionPlan.find(params[:id])
    
    if @plan.update(
      name: params[:name],
      price_cents: (params[:price].to_f * 100).to_i,
      billing_interval: params[:billing_interval],
      features: { included: params[:features].split("\n").map(&:strip) },
      stripe_price_id: params[:stripe_price_id],
      active: params[:active] == 'true'
    )
      flash[:success] = 'Subscription plan updated successfully'
      redirect '/admin/subscriptions'
    else
      flash[:error] = @plan.errors.full_messages.join(', ')
      erb :'admin/subscriptions/plans/edit', layout: :'layouts/admin'
    end
  end

  # History Content Management
  get '/admin/history' do
    @page_title = 'History Content'
    @periods = HistoricalPeriod.order(start_year: :asc)
    @artifacts = HistoricalArtifact.includes(:historical_period)
                                 .order(created_at: :desc)
                                 .paginate(page: params[:page], per_page: 20)
    @techniques = EmbroideryTechnique.order(:name)
    erb :'admin/history/index', layout: :'layouts/admin'
  end

  # Reports
  get '/admin/reports' do
    @page_title = 'Reports'
    @revenue_by_month = Subscription.active
                                  .joins(:subscription_plan)
                                  .group_by_month(:created_at)
                                  .sum('subscription_plans.price_cents')
                                  .transform_values { |cents| cents / 100.0 }
    
    @users_by_month = User.group_by_month(:created_at).count
    @subscriptions_by_plan = Subscription.active
                                       .joins(:subscription_plan)
                                       .group('subscription_plans.name')
                                       .count
    erb :'admin/reports/index', layout: :'layouts/admin'
  end

  # Settings
  get '/admin/settings' do
    @page_title = 'Settings'
    erb :'admin/settings/index', layout: :'layouts/admin'
  end

  private

  def require_admin
    unless current_user&.admin?
      flash[:error] = "You don't have permission to access this area"
      redirect '/'
    end
  end
end
