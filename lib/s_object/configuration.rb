module SObject
  class Configuration
    attr_accessor :salesforce_namespace
    attr_accessor :salesforce_oauth_token

    def initialize
      @salesforce_namespace = ''
      @salesforce_oauth_token = -> { '' }
    end
  end
end
