SolidStackWeb::Engine.routes.draw do
  root to: "dashboard#index"

  resource :job_selection,        path: "jobs/selection",        only: [:destroy],         controller: "jobs/selections"
  resource :failed_job_selection, path: "failed_jobs/selection", only: [:create, :destroy], controller: "failed_jobs/selections"

  resources :scheduled_jobs, only: [:update] do
    collection do
      post :run_all_now, action: :create
    end
  end

  resources :jobs, only: [:index, :show, :destroy] do
    collection do
      post :discard_all, action: :destroy
    end
  end

  resources :failed_jobs, only: [:index, :show, :destroy] do
    member { post :retry }
    resource :arguments, only: [:update], controller: "failed_jobs/arguments"
  end

  resources :queues, only: [:index] do
    member do
      post   :pause
      delete :resume
    end
  end

  resources :processes, only: [:index]

  get "cache", to: "cache#index", as: :cache
  get "cable", to: "cable#index", as: :cable
end
