source 'https://rubygems.org'

# Specify the global dependencies in puppetlabs_spec_helper.gemspec
gemspec

group :development do
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || ENV['PUPPET_VERSION'] || '~> 5.0'
  gem 'rubocop', '= 0.49.1'
  gem 'rubocop-rspec', '= 1.15.1'
end

# json_pure 2.0.2 added a requirement on ruby >= 2. We pin to json_pure 2.0.1
# if using ruby 1.x
gem 'json_pure', '<=2.0.1', :require => false if RUBY_VERSION =~ /^1\./
gem 'rack', '~> 1'

# vim:filetype=ruby
