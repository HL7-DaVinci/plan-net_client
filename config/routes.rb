# frozen_string_literal: true

Rails.application.routes.draw do
  get 'export/index'
  get 'export/export'
  get 'export/pollexport'
  get 'export/cancel'
  get 'pharmacymix/index'
  get 'controllername/pharmacymix'
  get 'controllername/index'
  get 'controllername/export'
  get 'controllername/exportpoll'
  get 'controllername/exportcancel'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'
  get '/welcome/export', to: 'welcome#export'
  get '/welcome/exportpoll', to: 'welcome#exportpoll'
  get '/welcome/exportcancel', to: 'welcome#exportcancel'

  resources :healthcare_services, only: [:index, :show] do
    get 'search', on: :collection
  end

  resources :pharmacies, only: [:index] do
    get 'search', on: :collection
  end

  resources :pharmacymixes, only: [:index] do
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
  resources :pharmacymixes,             only: [:index]
end
