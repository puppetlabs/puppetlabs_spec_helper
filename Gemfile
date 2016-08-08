source 'https://rubygems.org'

gem 'rake'
gem 'rspec-puppet'
gem 'rubocop', '0.41.2'
gem 'puppet-lint'
gem 'puppet-syntax'
gem 'mocha'

group :development do
  gem 'rspec', '~> 3'
  gem 'yard'
  gem 'pry'
  gem 'jeweler'
  gem "puppet", ENV['PUPPET_VERSION'] || '~> 3.8.3'
end

# json_pure 2.0.2 added a requirement on ruby >= 2. We pin to json_pure 2.0.1
# if using ruby 1.x
gem 'json_pure', '<=2.0.1', :require => false if RUBY_VERSION =~ /^1\./
gem 'rack', '~> 1'

# vim:filetype=ruby
