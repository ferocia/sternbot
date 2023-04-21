Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  post '/slack/incoming', 'slack#incoming'

  # Defines the root path route ("/")
  # root "articles#index"
  mount GoodJob::Engine => 'good_job'

end
