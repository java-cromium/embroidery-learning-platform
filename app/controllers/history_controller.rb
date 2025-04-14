class App < Sinatra::Base
  # Timeline view
  get '/history' do
    @periods = HistoricalPeriod.ordered
    @techniques = EmbroideryTechnique.all
    erb :'history/index'
  end

  # Historical period detail
  get '/history/periods/:id' do
    @period = HistoricalPeriod.find(params[:id])
    @artifacts = @period.historical_artifacts
    @related_techniques = EmbroideryTechnique.where(origin: @period.region)
    erb :'history/period'
  end

  # Artifact detail
  get '/history/artifacts/:id' do
    @artifact = HistoricalArtifact.find(params[:id])
    @period = @artifact.historical_period
    erb :'history/artifact'
  end

  # Technique detail
  get '/history/techniques/:id' do
    @technique = EmbroideryTechnique.find(params[:id])
    erb :'history/technique'
  end

  # Interactive map
  get '/history/map' do
    @periods = HistoricalPeriod.all
    erb :'history/map'
  end

  # Admin routes for historical content management
  # Historical Periods
  get '/admin/history/periods/new' do
    require_admin
    @period = HistoricalPeriod.new
    erb :'admin/history/periods/new'
  end

  post '/admin/history/periods' do
    require_admin
    @period = HistoricalPeriod.new(params[:period])
    if @period.save
      flash[:success] = "Historical period created successfully"
      redirect "/admin/history/periods/#{@period.id}/edit"
    else
      flash[:error] = @period.errors.full_messages.join(", ")
      erb :'admin/history/periods/new'
    end
  end

  get '/admin/history/periods/:id/edit' do
    require_admin
    @period = HistoricalPeriod.find(params[:id])
    erb :'admin/history/periods/edit'
  end

  put '/admin/history/periods/:id' do
    require_admin
    @period = HistoricalPeriod.find(params[:id])
    if @period.update(params[:period])
      flash[:success] = "Historical period updated successfully"
      redirect "/admin/history/periods/#{@period.id}/edit"
    else
      flash[:error] = @period.errors.full_messages.join(", ")
      erb :'admin/history/periods/edit'
    end
  end

  # Artifacts
  get '/admin/history/artifacts/new' do
    require_admin
    @artifact = HistoricalArtifact.new
    @periods = HistoricalPeriod.all
    erb :'admin/history/artifacts/new'
  end

  post '/admin/history/artifacts' do
    require_admin
    @artifact = HistoricalArtifact.new(params[:artifact])
    if @artifact.save
      flash[:success] = "Historical artifact created successfully"
      redirect "/admin/history/artifacts/#{@artifact.id}/edit"
    else
      @periods = HistoricalPeriod.all
      flash[:error] = @artifact.errors.full_messages.join(", ")
      erb :'admin/history/artifacts/new'
    end
  end

  # Techniques
  get '/admin/history/techniques/new' do
    require_admin
    @technique = EmbroideryTechnique.new
    erb :'admin/history/techniques/new'
  end

  post '/admin/history/techniques' do
    require_admin
    @technique = EmbroideryTechnique.new(params[:technique])
    if @technique.save
      flash[:success] = "Embroidery technique created successfully"
      redirect "/admin/history/techniques/#{@technique.id}/edit"
    else
      flash[:error] = @technique.errors.full_messages.join(", ")
      erb :'admin/history/techniques/new'
    end
  end
end
