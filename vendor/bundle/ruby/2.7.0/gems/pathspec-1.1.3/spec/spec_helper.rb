begin
  require 'simplecov'
  SimpleCov.start
rescue StandardError
  puts 'SimpleCov failed to start, most likely this due to running Ruby 1.8.7'
end
