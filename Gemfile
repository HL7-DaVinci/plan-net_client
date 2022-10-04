# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.10'

gem 'puma', '~> 3.11'           # Use Puma as the app server
gem 'rails', '~> 5.2.3'         # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'sass-rails', '~> 5.0'      # Use SCSS for stylesheets
gem 'uglifier', '>= 1.3.0'      # Use Uglifier as compressor for JavaScript assets
gem 'httparty', '>=  0.17.1'    # use httparty for geocoder access

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby    # Minimal embedded v8 engine for Ruby

gem 'coffee-rails', '~> 4.2'    # Use CoffeeScript for .coffee assets and views
gem 'jbuilder', '~> 2.5'        # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder

# gem 'redis', '~> 4.0'         # Use Redis adapter to run Action Cable in production
# gem 'bcrypt', '~> 3.1.7'      # Use ActiveModel has_secure_password
# gem 'mini_magick', '~> 4.8'   # Use ActiveStorage variant

gem 'bootsnap', '>= 1.1.0', require: false # Reduces boot times through caching; required in config/boot.rb

gem 'bootstrap', '~> 4.3.1'     # Integrates Bootstrap HTML, CSS, and JavaScript framework
gem 'fhir_client'               # Handles FHIR client requests
gem 'jquery-rails'              # Automate using jQuery with Rails
gem 'leaflet-awesome-markers-rails', '~> 2.0'  
                                # Custom markers for Leaflet
    
gem 'leaflet-rails'             # Handles Leaflet-based maps
gem 'pg'                        # Use Postgres
gem 'geokit-rails'              # Provides geolocation-based searches
gem 'dalli'                     # Memcache client

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw] # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'rubocop'
  gem 'seed_dump'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'   # Listens to file modifications and notifies you about the changes
  gem 'spring'                        # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'       # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'capistrano-rails'            # Use Capistrano for deployment
end

group :test do
  gem 'capybara', '>= 2.15'     # Adds support for Capybara system testing and selenium driver
  gem 'chromedriver-helper'     # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'selenium-webdriver'      # WebDriver JavaScript bindings from the Selenium project
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem

gem "pry", "~> 0.12.2"
