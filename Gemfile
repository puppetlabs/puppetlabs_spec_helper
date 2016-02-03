source 'https://rubygems.org'

gem 'rake'
gem 'rspec-puppet'
gem 'puppet-lint'
gem 'puppet-syntax'
gem 'mocha'

group :development do
  gem 'yard'
  gem 'pry'
  gem 'jeweler'
  gem "puppet", ENV['PUPPET_VERSION'] || '~> 3.8.3'
end

group :test do
end

# I don't know the purpose of this below
if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

# vim:filetype=ruby
