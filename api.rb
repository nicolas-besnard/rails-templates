@has_rspec = false

environment '
    config.generators do |g|
      g.assets false
      g.helper false
      g.template_engine false
    end
'

environment 'config.time_zone = \'UTC\''

if yes?('Rspec ?')
  gem_group :development, :test do
    gem 'rspec-rails', '~> 3.0'
    gem 'faker'
    gem 'factory_girl_rails'
    gem 'guard-rspec'
    gem 'spring-commands-rspec'
  end

  gem_group :test do
    gem 'database_cleaner'
    gem 'json-schema'
    gem 'shoulda-matchers'
  end
  
  run 'bundle install'
  run 'rails generate rspec:install'
  run 'bundle exec spring binstub rspec'
  @has_rspec = true
end

gem_group :development do
  gem 'quiet_assets'
  gem 'annotate'
  gem 'rails-erd'
  gem 'rubocop'
  gem 'pry-rails'
end

# New Relic
gem 'newrelic_rpm'
create_file "config/newrelic.yml" do <<-FILE
common: &default_settings
  app_name: <%= ENV['NEW_RELIC_APP_NAME'] %>
  audit_log:
    enabled: false
  browser_monitoring:
    auto_instrument: true
  capture_params: false
  developer_mode: false
  error_collector:
    capture_source: true
    enabled: true
    ignore_errors: "ActionController::RoutingError,Sinatra::NotFound"
  license_key: '<%= ENV["NEW_RELIC_LICENSE_KEY"] %>'
  log_level: info
  monitor_mode: true
  transaction_tracer:
    enabled: true
    record_sql: obfuscated
    stack_trace_threshold: 0.500
    transaction_threshold: apdex_f
development:
  <<: *default_settings
  monitor_mode: true
  developer_mode: true
test:
  <<: *default_settings
  monitor_mode: false
production:
  <<: *default_settings
  monitor_mode: true
staging:
  <<: *default_settings
  app_name: "AppTest (Staging)"
  monitor_mode: true

FILE
end

# Database
remove_file 'config/database.yml'
create_file 'config/database.yml' do <<-FILE
default: &default
  adapter: postgresql
  encoding: utf8
  pool: 2
  timeout: 5000
  min_message: warning
  database: app_name_<%= Rails.env %>
  username: <%= ENV['DB_USERNAME'] %>
  password: <%= ENV['DB_PASSWORD'] %>
  host: <%= ENV['DB_HOSTNAME'] %>
  port: <%= ENV['DB_PORT'] %>

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
FILE
end

gem 'figaro'
gem 'puma'

run 'bundle install'

# Figaro
run 'figaro install'

create_file "config/application.yml" do <<-FILE
defaults: &defaults

development:
  <<: *defaults
  DB_USERNAME:
  DB_PASSWORD:
  DB_HOSTNAME:
  DB_PORT:

  NEW_RELIC_APP_NAME:
  NEW_RELIC_LICENSE_KEY:
test:
  <<: *defaults
FILE
end

if @has_rspec && yes?('SimpleCov ?')
  prepend_file 'spec/spec_helper.rb' do <<-FILE
require 'simplecov'
SimpleCov.start 'rails'
  FILE
  end

  gem_group :test do
    gem 'simplecov'
  end
  run 'bundle install'
end

if yes?('Capistrano ?')
  gem_group :development do
    gem 'capistrano'
    gem 'capistrano3-puma', require: false
    gem 'capistrano-rails', require: false
    gem 'capistrano-bundler', require: false
    gem 'capistrano-rvm', require: false
    gem 'airbrussh', require: false
  end

  run 'bundle install'
  run 'bundle exec cap install'

  run 'bundle exec cap install STAGES=production,development'
end

run 'bundle exec spring binstub --all'

git :init

append_file '.gitignore', "coverage\n"
append_file '.gitignore', ".idea\n"
append_file '.gitignore', ".DS_Store\n"

git add: '.'
git commit: "-a -m 'Initial commit'"
