Rails.application.routes.draw do
  # Liveness probe for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      resources :employees, only: %i[index show create update destroy] do
        resources :salaries, only: %i[index create]
      end

      get "meta/filters", to: "meta#filters"

      scope "insights", controller: "insights", as: "insights" do
        get :summary
        get :by_country
        get :by_department
        get :job_titles
        get :outliers
      end
    end
  end
end
