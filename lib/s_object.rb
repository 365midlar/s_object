require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 's_object/version'
require 's_object/configuration'
require 's_object/s_object'

module SObject
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
