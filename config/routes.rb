Rails.application.routes.draw do
  resources :entries, only: [ :index, :new, :create, :show, :destroy ] do
    member do
      post :generate_guide
    end
  end

  root "entries#index"
end
