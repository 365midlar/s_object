module SObject
  class Configuration
    attr_accessor :salesforce_namespace
    attr_accessor :salesforce_client

    def initialize
      @salesforce_namespace = ''
      @salesforce_client = -> { Restforce.new }
    end
  end
end
