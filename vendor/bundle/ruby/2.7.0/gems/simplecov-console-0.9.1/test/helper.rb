
$LOAD_PATH.push(File.expand_path("../../lib", __FILE__))

require "bundler/setup"
require "simplecov"
require "simplecov-console"

SimpleCov.start do
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])
end

require "minitest/autorun"
