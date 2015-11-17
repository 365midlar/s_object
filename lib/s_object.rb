require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 's_object/version'
require 's_object/configuration'
require 's_object/s_object'

# An ORM-like mapping object for Salesforce
module SObject
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure(&_block)
    yield(configuration) if block_given?
  end
end
