source 'https://rubygems.org'

# Specify the global dependencies in puppetlabs_spec_helper.gemspec
gemspec

group :development do
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || ENV['PUPPET_VERSION'] || '~> 5.0'
  gem 'rubocop'
  gem 'rubocop-rspec', '~> 1.6' if RUBY_VERSION >= '2.3.0'
end

gem 'rack', '~> 1'

# vim:filetype=ruby
