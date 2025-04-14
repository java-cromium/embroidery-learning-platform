Rails.application.routes.draw do
  namespace :admin do
    resources :filter_presets, only: [:index, :create, :update, :destroy] do
      post :apply, on: :member
    end
    
    resources :users do
      collection do
        get :export
      end
    end
    
    resources :subscriptions do
      collection do
        get :export
      end
    end
  end
end
