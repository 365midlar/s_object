module SObject
  # SObject Configuration class for setting client and custom namespace
  class Configuration
    attr_accessor :namespace
    attr_accessor :salesforce_client

    def initialize
      @namespace = ''
      @salesforce_client = -> { Restforce.new }
    end
  end
end
