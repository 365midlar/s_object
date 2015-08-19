module SObject
  class Configuration
    attr_accessor :salesforce_namespace

    def initialize
      @salesforce_namespace = ''
    end
  end
end
