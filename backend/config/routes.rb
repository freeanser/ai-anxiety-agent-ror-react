# Rails.application.routes.draw do
#   # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

#   # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
#   # Can be used by load balancers and uptime monitors to verify that the app is live.
#   get "up" => "rails/health#show", as: :rails_health_check

#   # Defines the root path route ("/")
#   # root "posts#index"
# end

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'gemini/analyze_worries', to: 'gemini#analyze_worries'
      post 'gemini/generate_steps', to: 'gemini#generate_steps'
      post 'gemini/generate_plan', to: 'gemini#generate_plan'
      post 'gemini/process_unplanned_task', to: 'gemini#process_unplanned_task'
    end
  end
end