Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  resources :insurance_plans, 		only: [:index, :show]
  resources :care_teams, 			only: [:index, :show]
  resources :healthcare_services, 	only: [:index, :show]
  resources :networks, 				only: [:index, :show]
  resources :organizations, 		only: [:index, :show]
  resources :practitioners, 		only: [:index, :show]
  resources :endpoints,				only: [:index, :show]
end
