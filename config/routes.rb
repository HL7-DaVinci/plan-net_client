# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  resources :endpoints,                 only: [:index, :show]
  resources :healthcare_services,       only: [:index, :show]
  resources :insurance_plans, only: [:index, :show]
  resources :locations,                 only: [:index, :show]
  resources :networks,                  only: [:index, :show]
  resources :organizations, only: [:index, :show]
  resources :organization_affiliations, only: [:index, :show]
  resources :practitioners, only: [:index, :show]
  resources :practitioner_roles,        only: [:index, :show]
  resources :providers,                 only: [:index]
  resources :pharmacies, only: [:index]

  get '/providers/networks', to: 'providers#networks'
  get '/providers/search', to: 'providers#search'

  get '/pharmacies/networks', to: 'pharmacies#networks'
  get '/pharmacies/search', to: 'pharmacies#search'
end
