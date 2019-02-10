source "https://rubygems.org"

ruby File.read(".ruby-version").chomp

gem "bunny", "~> 2.12"
gem "gds-api-adapters", "~> 57.2"
gem "govuk_app_config", "~> 1.11"
gem "plek", "~> 2.1"
gem "rake"
gem "redis", "~> 4.1"
gem "redis-namespace", "~> 1.6"
gem "tzinfo", "~> 1.2"
gem "tzinfo-data", "~> 1.2018"

group :development, :test do
  gem "govuk-lint", "~> 3.10"
  gem "pry-byebug"
end

group :test do
  gem 'govuk_schemas', '~> 3.2'
  gem 'rspec-core', '~> 3.8'
  gem 'rspec-expectations', '~> 3.8'
  gem 'rspec-mocks', '~> 3.8'
  gem 'webmock', '~> 3.5'
end
