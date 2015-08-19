$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 's_object'

require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/mini_test'
require 'byebug'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

SObject.configure do |config|
  config.salesforce_namespace = 'Test'
end
