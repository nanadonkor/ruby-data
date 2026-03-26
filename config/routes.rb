Rails.application.routes.draw do
  resources :entries, only: [ :index, :new, :create, :show, :destroy ] do
    member do
      post :generate_guide
    end
  end

  resources :knowledge_documents, only: [ :index, :new, :create ]
  root "entries#index"
end