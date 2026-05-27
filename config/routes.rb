SolidStackWeb::Engine.routes.draw do
  root to: "dashboard#index"

  resource :job_selection,        path: "jobs/selection",        only: [:destroy],         controller: "jobs/selections"
  resource :failed_job_selection, path: "failed_jobs/selection", only: [:create, :destroy], controller: "failed_jobs/selections"

  resources :recurring_tasks, only: [:index], param: :key do
    resource :run, only: [:create], controller: "recurring_tasks/runs"
  end

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

  get "failed_jobs/errors", to: "failed_jobs/errors#index", as: :failed_job_errors

  resources :failed_jobs, only: [:index, :show, :destroy] do
    member { post :retry }
    resource :arguments, only: [:update], controller: "failed_jobs/arguments"
  end

  resources :queues, only: [:index, :show] do
    resource :pause, only: [:create, :destroy], controller: "queues/pauses"
  end

  resources :processes, only: [:index]

  get "metrics", to: "metrics#index", as: :metrics
  get "stats",   to: "stats#index",   as: :stats
  get "history", to: "history#index", as: :history
  get "cache", to: "cache#index", as: :cache
  resources :cache_entries, only: [:index, :show, :destroy], path: "cache/entries"
  resource  :cache_flush,   only: [:destroy],         path: "cache/flush",    controller: "cache/flushes"
  get    "cable",                                  to: "cable#index",                          as: :cable
  delete "cable/purge",                            to: "cable/purges#destroy",                 as: :cable_purge
  get    "cable/channels/:channel_hash",           to: "cable_messages#index",                 as: :cable_channel_messages
  delete "cable/channels/:channel_hash/purge",     to: "cable/channel_purges#destroy",         as: :cable_channel_purge
end
