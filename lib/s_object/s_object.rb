module SObject
  def self.valid_external_id?(external_id)
    !(/^([A-Za-z0-9]){15}([A-Z0-9]{3})?$/ =~ external_id).nil?
  end

  # This class is inherited by objects which will reflect a given Salesforce object. Defined using DSL methods you can configure which Salesforce object, fields, and relationships are reflected.
  class SObject
    class << self; attr_accessor :s_object_name end
    class << self; attr_accessor :s_object_api_name end

    def initialize(*args)
      # make sure we have a valid object name
      raise RuntimeError.new('SObject does not define an object name') if self.class.s_object_api_name.blank?

      values = args.first
      options = args.second

      # initialize field values
      init_fields(values, options)
    end

    def self.salesforce_namespace
      ::SObject.configuration.salesforce_namespace
    end

    # Saves this record to salesforce
    def save
      if new_record?
        self.external_id = self.class.client.create(self.class.s_object_api_name, remote_attributes)
        return !self.external_id.blank?
      else
        return self.class.client.update(self.class.s_object_api_name, remote_attributes)
      end
    end

    def save!
      if new_record?
        self.external_id = self.class.client.create!(self.class.s_object_api_name, remote_attributes)
        return !self.external_id.blank?
      else
        self.class.client.update!(self.class.s_object_api_name, remote_attributes)
      end
    end

    # Checks if this record has been saved to salesforce or not
    def new_record?
      external_id.blank?
    end

    def assign_attributes(attributes={})
      attributes.symbolize_keys.each do |k,v|
        send(:"#{k.to_s}=", v) if self.class.local_fields.keys.include?(k)
      end
    end

    # Update this record in salesforce using the values in this record but throws an exception if save is unsuccessful
    def update(attributes={})
      assign_attributes(attributes)
      save
    end

    # Update the values of the instance variables in local_fields and return false if save fails
    def update!(attributes={})
      assign_attributes(attributes)
      save!
    end

    # Create a new record in salesforce using the values in this record
    def self.create(attributes={})
      object = new(attributes)
      object.save
      object
    end

    def self.create!(attributes={})
      object = new(attributes)
      object.save!
      object
    end

    # Get a hash of the values with the salesforce field names as keys
    def remote_attributes
      attributes.map{ |k,v| [self.class.local_fields[k], v] }.to_h
    end

    # Returns the values for this instance as a hash with keys corresponding to the instance variable name, excluding the local parent id field names.
    # @param options [Hash] The options hash.
    # @option options [Boolean] :include_parent_ids If the local parent id fields should be included, default +false+.
    def to_h(options={})
      self.class.local_fields
        .select { |k,v| (not self.class.local_parent_id_fields.include?(k) or options[:include_parent_ids]) }
        .map{ |k,v| [k, instance_variable_get("@#{k}")] }.to_h
    end
    alias_method :attributes, :to_h

    ###
    # Mapping definitions
    #

    # Specifies which salesforce object this class will reflect.
    # @param name [String] The name of the salesforce object which this class will reflect.
    # @param options [Hash] The options hash.
    # @option options [Boolean] :custom If this is +true+, then +__c+ will be added to the name, unless it's already been added.
    def self.maps_object(name, options={})
      self.s_object_name = "#{name}"
      self.s_object_api_name = "#{options[:api_name] || s_object_name}"

      # override with custom settings
      if options[:custom]
        self.s_object_api_name = "#{self.s_object_api_name}__c" unless self.s_object_api_name.end_with?('__c')
      end
    end

    # Specifies which salesforce object this class will reflect.
    # @see SObject#self.maps_object
    # @note The +custom+ option is forced to +true+.
    def self.maps_custom_object(name, options={})
      self.maps_object(name, options.merge({custom: true}))
    end
    # Adds a new salesforce field this class will reflect. # @param local [Symbol] The name of the instance variable.
    # @param remote [Symbol] The name of the field in Salesforce.
    # @param options [Hash] The options hash.
    # @option options [Boolean] :custom If this is +true+, then +__c+ , unless it's already been added.
    def self.maps_field(local, remote, options={})
      if options[:custom]
        remote = :"#{"#{salesforce_namespace}__" unless salesforce_namespace.blank?}#{remote}__c"
      end
      remote_fields[remote] = local
      remote_id_fields[remote] = local if options[:id]
    end

    # Adds a new salesforce field this class will reflect.
    # @see SObject#self.map_field
    # @note The +custom+ option is forced to +true+.
    def self.maps_custom_field(local, remote, options={})
      maps_field(local, remote, options.merge({custom: true}))
    end

    # Maps this object to a parent object.
    # @param local [Symbol] The name of the instance variable which references the related object.
    # @param options [Hash] The options hash.
    # @option options [Symbol] :class The name of the parent class object. Defaults to +:"#{local.capitalize}SObject"+, e.g. +:AccountSObject+.
    # @option options [Symbol] :local_foreign_key The name of the instance variable which references the related id value. Defaults to +:"#{local}_id"+, e.g. +:account_id+.
    # @option options [Symbol] :remote_foreign_key The name of the field on the Salesforce object which references the related id value. Defaults to +:"#{Rails.application.secrets.salesforce_namespace}#{local_id.to_s.camelcase}"+, e.g. +AccountId+.
    def self.maps_parent(local, options={})
      class_name = options.fetch(:class) { :"#{local.capitalize}SObject" }
      local_id = options.fetch(:local_foreign_key) { :"#{local}_id" }
      remote_id = options.fetch(:remote_foreign_key) { :"#{local_id.to_s.camelcase}" }
      if options[:custom]
        remote_id = :"#{"#{salesforce_namespace}__" unless salesforce_namespace.blank?}{remote_id}"
      end
      maps_field(local_id, remote_id, options)
      remote_parent_id_fields[remote_id] = local_id
      remote_id_fields[remote_id] = local_id

      define_method(local) do
        id_value = self.send(local_id)
        return nil unless id_value
        class_name.to_s.constantize.find(id_value)
      end
    end

    # Maps this object to a parent object.
    # @see SObject#self.maps_parent
    # @note The +custom+ option is forced to +true+.
    def self.maps_custom_parent(local, options={})
      maps_parent(local, options.merge({ custom: true }))
    end

    # Maps this object to a child object.
    # @param local [Symbol] The name of the instance variable which references the related obejcts.
    # @param options [Hash] The options hash.
    # @option options [Symbol] :class The name of the child class object. Defaults to +:"#{local.to_s.singularize.capitalize}SObject"+, e.g. +ContactSObject+.
    # @option options [Symbol] :foreign_key The name of the foreign key instance variable on the related object. Defaults to +:"#{self.class.s_object_api_name.underscore}_id"+, e.g. +account_id+.
    def self.maps_children(local, options={})
      class_name = options.fetch(:class) { :"#{local.to_s.singularize.capitalize}SObject" }
      local_id = options.fetch(:foreign_key) { :"#{s_object_api_name.underscore}_id" }

      define_method(local) do
        id_value = self.send(:external_id)
        SObjectCollectionProxy.new(class_name.to_s.constantize, self, local_id)
      end
    end

    # Maps this object to a child object.
    # @see SObject#self.maps_children
    # @note The +custom+ option is forced to +true+.
    def self.maps_custom_children(local, options={})
      maps_children(local, options.merge({ custom: true }))
    end

    # A hash map of the remote field names against the local field names.
    def self.remote_fields
      @remote_fields ||= {Id: :external_id}
    end

    # A hash map of the local field names against the remote field names.
    def self.local_fields
      remote_fields.invert
    end

    # A hash map of the remote id field names against the local id field names.
    def self.remote_id_fields
      @remote_id_fields ||= {Id: :external_id}
    end

    # A hash map of the local id field names against the remote id field names.
    def self.local_id_fields
      remote_id_fields.invert
    end

    # A hash map of the remote parent id field names against the remote parent id field names.
    def self.remote_parent_id_fields
      @remote_parent_id_fields ||= {}
    end

    # A hash map of the local parent id field names agains the remote parent id field names.
    def self.local_parent_id_fields
      remote_parent_id_fields.invert
    end

    ###
    # Finders
    #

    # Find a record in Salesforce.
    # @param external_id [String] The record Id in Salesforce.
    def self.find(external_id)
      self.new(client.find(s_object_api_name, external_id).to_h.symbolize_keys, { translate: true })
    end

    # Find a record in Salesforce which satisfy the given conditions.
    # @param conditions [Hash] The query conditions, where the keys are local field names and the values the constraints.
    def self.find_by(conditions={})
      where(conditions).first
    end

    # Find a list of records in Salesforce which satisfy the given conditions.
    # @param conditions [Hash] The query conditions, where the keys are local field names and the values the constraints.
    def self.where(conditions={})
      client.query("SELECT #{remote_fields.keys.join(',')}
                    FROM #{s_object_api_name}
                    #{"WHERE #{where_conditions(conditions)}" unless conditions.blank?}")
      .map do |obj|
        self.new(obj.to_h.symbolize_keys, { translate: true })
      end
    end

    def self.exists?(conditions={})
      client.query("SELECT Id
                    FROM #{s_object_api_name}
                    #{"WHERE #{where_conditions(conditions)}" unless conditions.blank?}
                    LIMIT 1")
      .map do |obj|
        return true
      end
      return false
    end

    # Get all records in Salesforce.
    def self.all
      where
    end

    ###
    # Client interaction
    #

    # The Salsforce client.
    def self.client
      force_client = ::SObject.configuration.salesforce_client.call()
      raise RuntimeError("Unable to establish Restforce client") if force_client.nil?
      force_client
    end

    # Create a new instance of this class with the given parameters.
    # @param *args [Hash] The values for the local fields.
    def self.build(*args)
      self.new(*args)
    end

    # Create a new instance of this class with the given parameters and save it to Salesforce.
    def self.create(*args)
      self.build(*args).save
    end

    ###
    # Transformations and filtering
    #

    private

    def clean_field_values(field_values, options={})
      keys = options[:translate] ? self.class.remote_id_fields.keys : self.class.local_id_fields.keys
      field_values.map{ |k,v| [k, ((keys.include?(k) && not(v.nil?)) ? v.slice(0, 15) : v)] }.to_h
    end

    def init_fields(field_values=nil, options=nil)
      field_values ||= {}
      options ||= {}

      field_values = clean_field_values(field_values, options)

      self.class.local_fields.each do |k,_|
        value_field = options[:translate] ? self.class.local_fields[k] : k
        self.class.send(:attr_accessor, k)
        instance_variable_set("@#{k}", field_values[value_field])
      end
    end

    def self.where_conditions(args={})
      conditions = []
      args.map do |k,v|
        unless local_fields.keys.include?(k)
          raise ArgumentError.new("'#{k}' is not an attribute of #{s_object_api_name}")
        end
        conditions << "#{remote_fields.invert[k]} = '#{v}'" if k
      end
      conditions.join(' AND ')
    end

    class << self
      # aliased class methods
      alias_method :maps_standard_object, :maps_object
      alias_method :maps_standard_parent, :maps_parent
      alias_method :maps_standard_children, :maps_children
      alias_method :maps_standard_field, :maps_field
    end
  end

  class SObjectCollectionProxy
    attr_accessor :parent, :sobject, :field_name

    def initialize(sobject, parent, field_name)
      @sobject = sobject
      @parent = parent
      @field_name = field_name
    end

    # Find a record in Salesforce.
    # @param external_id [String] The record Id in Salesforce.
    def find(external_id)
      sobject.find_by(scope_query_hash({external_id: external_id}))
    end

    # Find a record in Salesforce which staisfy the given conditions.
    # @param conditions [Hash] The query conditions, where the keys are local field names and the values the constraints.
    def find_by(conditions={})
      where(conditions).first
    end

    # Find a list of records in Salesforce which statisfy the given conditions.
    # @param conditions [Hash] The query conditions, where the keys are local field names and the values the constraints.
    def where(conditions={})
      sobject.where(scope_query_hash(conditions))
    end
    alias_method :all, :where

    private

    def scope_query_hash(hash)
      hash ||= {}
      hash[:"#{field_name}"] = parent.external_id
      hash
    end
  end
end
