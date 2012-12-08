Rails.application.routes.draw do
  put 'mercury_pages_update' => 'mercury_pages#update'

  scope "(/:locale)" do
    get 'pages/*id' => 'pages#show', :as => 'mercury_page'
  end
end
