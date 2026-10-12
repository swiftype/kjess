if ENV['COVERAGE']
  require 'simplecov'
  puts "Using coverage!"
  SimpleCov.start
end

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'kjess'
require 'utils'
require 'thread'
