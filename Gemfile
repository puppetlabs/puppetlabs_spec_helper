# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

if ENV['PUPPET_GEM_VERSION']
  gem 'puppet', ENV['PUPPET_GEM_VERSION'], :require => false
else
  gem 'puppet', :require => false
end

group :development do
  gem 'codecov'
  gem 'simplecov'
  gem 'simplecov-console'

  gem 'pry', require: false
  gem 'pry-byebug', require: false
  gem 'pry-stack_explorer', require: false

  gem 'rake'
  gem 'rspec', '~> 3.1'
  gem 'rspec-its', '~> 1.0'
  gem 'rubocop', '~> 1.6.1', require: false
  gem 'rubocop-rspec', '~> 2.0.1', require: false
  gem 'rubocop-performance', '~> 1.10.2', require: false

  gem 'fakefs'
  gem 'yard'
end


# Evaluate Gemfile.local if it exists
if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

# Evaluate ~/.gemfile if it exists
if File.exists?(File.join(Dir.home, '.gemfile'))
  eval(File.read(File.join(Dir.home, '.gemfile')), binding)
end
