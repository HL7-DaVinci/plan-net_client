# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  resources :healthcare_services, only: [:index, :show] do
    get 'search', on: :collection
  end

  resources :pharmacies, only: [:index] do
    get 'search', on: :collection
  end

  get '/providers/networks', to: 'providers#networks'
  get '/providers/search', to: 'providers#search'

  resources :endpoints,                 only: [:index, :show]
  resources :insurance_plans,           only: [:index, :show]
  resources :locations,                 only: [:index, :show]
  resources :networks,                  only: [:index, :show]
  resources :organizations,             only: [:index, :show]
  resources :organization_affiliations, only: [:index, :show]
  resources :practitioners,             only: [:index, :show]
  resources :practitioner_roles,        only: [:index, :show]
  resources :providers,                 only: [:index]
  resources :pharmacies,                only: [:index]

  # This is a bit of a hack, but seeding the zipcodes into the database
  # through the traditional 'rake db:seed' or 'bundle exec rake db:seed' 
  # results in a stack overflow error, apparently through the validation
  # logic.
  #
  # If you have access to the command line, you can just use 
  # 'rails db/seeds.rb' instead of making this call.
  
  get '/seed', to: 'seed#index'
end
