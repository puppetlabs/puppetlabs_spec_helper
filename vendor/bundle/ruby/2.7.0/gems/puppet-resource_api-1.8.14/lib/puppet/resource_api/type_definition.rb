# frozen_string_literal: true

# Provides accessor methods for the type being provided
module Puppet::ResourceApi
  # pre-declare class
  class BaseTypeDefinition; end

  # RSAPI Resource Type
  class TypeDefinition < BaseTypeDefinition
    def initialize(definition)
      super(definition, :attributes)
    end

    def ensurable?
      attributes.key?(:ensure)
    end

    # rubocop complains when this is named has_feature?
    def feature?(feature)
      definition[:features]&.include?(feature)
    end

    def title_patterns
      definition[:title_patterns] ||= []
    end

    def validate_schema(definition, attr_key)
      super(definition, attr_key)
      [:title, :provider, :alias, :audit, :before, :consume, :export, :loglevel, :noop, :notify, :require, :schedule, :stage, :subscribe, :tag].each do |name|
        raise Puppet::DevError, 'must not define an attribute called `%{name}`' % { name: name.inspect } if definition[attr_key].key? name
      end
      if definition.key?(:title_patterns) && !definition[:title_patterns].is_a?(Array)
        raise Puppet::DevError, '`:title_patterns` must be an array, not `%{other_type}`' % { other_type: definition[:title_patterns].class }
      end

      Puppet::ResourceApi::DataTypeHandling.validate_ensure(definition)

      definition[:features] ||= []
      supported_features = %w[supports_noop canonicalize custom_insync remote_resource simple_get_filter].freeze
      unknown_features = definition[:features] - supported_features
      Puppet.warning("Unknown feature detected: #{unknown_features.inspect}") unless unknown_features.empty?
    end

    # This call creates a new parameter or property with all work-arounds or
    # customizations required by the Resource API applied. Under the hood,
    # this maps to the relevant DSL methods in Puppet::Type. See
    # https://puppet.com/docs/puppet/6.0/custom_types.html#reference-5883
    # for details.
    #
    # type: the Resource API Type the attribute is being created in
    # attribute_name: the name of the attribute being created
    # param_or_property: Whether to call the :newparam or :newproperty method
    # parent: The type of attribute to create: Property, ReadOnly, or Parameter
    # options: The hash of attribute options, including type, desc, default, and behaviour
    def create_attribute_in(type, attribute_name, param_or_property, parent, options)
      type.send(param_or_property, attribute_name.to_sym, parent: parent) do
        if options[:desc]
          desc "#{options[:desc]} (a #{options[:type]})"
        end

        # The initialize method is called when puppet core starts building up
        # type objects. The core passes in a hash of shape { resource:
        # #<Puppet::Type::TypeName> }. We use this to pass through the
        # required configuration data to the parent (see
        # Puppet::ResourceApi::Property, Puppet::ResourceApi::Parameter and
        # Puppet::ResourceApi::ReadOnlyParameter).
        define_method(:initialize) do |resource_hash|
          super(type.name, self.class.data_type, attribute_name, resource_hash, type)
        end

        # get pops data type object for this parameter or property
        define_singleton_method(:data_type) do
          @rsapi_data_type ||= Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
            attribute_name,
            options[:type],
          )
        end

        # from ValueCreator call create_values which makes alias values and
        # default values for properties and params
        Puppet::ResourceApi::ValueCreator.create_values(
          self,
          data_type,
          param_or_property,
          options,
        )
      end
    end
  end

  # RSAPI Transport schema
  class TransportSchemaDef < BaseTypeDefinition
    def initialize(definition)
      super(definition, :connection_info)
    end

    def validate(resource)
      # enforce mandatory attributes
      missing_attrs = []

      attributes.each do |name, _options|
        type = @data_type_cache[attributes[name][:type]]

        if resource[name].nil? && !(type.instance_of? Puppet::Pops::Types::POptionalType)
          missing_attrs << name
        end
      end

      error_msg = "The following mandatory attributes were not provided:\n    *  " + missing_attrs.join(", \n    *  ")
      raise Puppet::ResourceError, error_msg if missing_attrs.any?
    end

    def notify_schema_errors(message)
      raise Puppet::DevError, message
    end
  end

  # Base RSAPI schema Object
  class BaseTypeDefinition
    attr_reader :definition, :attributes

    def initialize(definition, attr_key)
      @data_type_cache = {}
      validate_schema(definition, attr_key)
      # store the validated definition
      @definition = definition
    end

    def name
      definition[:name]
    end

    def namevars
      @namevars ||= attributes.select { |_name, options|
        options.key?(:behaviour) && options[:behaviour] == :namevar
      }.keys
    end

    def insyncable_attributes
      @insyncable_attributes ||= attributes.reject { |_name, options|
        # Only attributes without any behavior are normal Puppet Properties and get insynced
        options.key?(:behaviour)
      }.keys
    end

    def validate_schema(definition, attr_key)
      raise Puppet::DevError, '%{type_class} must be a Hash, not `%{other_type}`' % { type_class: self.class.name, other_type: definition.class } unless definition.is_a?(Hash)
      @attributes = definition[attr_key]
      raise Puppet::DevError, '%{type_class} must have a name' % { type_class: self.class.name } unless definition.key? :name
      raise Puppet::DevError, '%{type_class} must have `%{attr_key}`' % { type_class: self.class.name, attrs: attr_key } unless definition.key? attr_key
      unless attributes.is_a?(Hash)
        raise Puppet::DevError, '`%{name}.%{attrs}` must be a hash, not `%{other_type}`' % {
          name: definition[:name], attrs: attr_key, other_type: attributes.class
        }
      end

      # fixup desc/docs backwards compatibility
      if definition.key? :docs
        if definition[:desc]
          raise Puppet::DevError, '`%{name}` has both `desc` and `docs`, prefer using `desc`' % { name: definition[:name] }
        end
        definition[:desc] = definition[:docs]
        definition.delete(:docs)
      end
      Puppet.warning('`%{name}` has no documentation, add it using a `desc` key' % { name: definition[:name] }) unless definition.key? :desc

      attributes.each do |key, attr|
        raise Puppet::DevError, '`rsapi_custom_insync_trigger` cannot be specified as an attribute; it is reserved for propertyless types with the custom_insync feature' if key == :rsapi_custom_insync_trigger # rubocop:disable Metrics/LineLength
        raise Puppet::DevError, "`#{definition[:name]}.#{key}` must be a Hash, not a #{attr.class}" unless attr.is_a? Hash
        raise Puppet::DevError, "`#{definition[:name]}.#{key}` has no type" unless attr.key? :type
        Puppet.warning('`%{name}.%{key}` has no documentation, add it using a `desc` key' % { name: definition[:name], key: key }) unless attr.key? :desc

        # validate the type by attempting to parse into a puppet type
        @data_type_cache[attributes[key][:type]] ||=
          Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
            key,
            attributes[key][:type],
          )

        # fixup any weird behavior  ;-)
        next unless attr[:behavior]
        if attr[:behaviour]
          raise Puppet::DevError, "the '#{key}' attribute has both a `behavior` and a `behaviour`, only use one"
        end
        attr[:behaviour] = attr[:behavior]
        attr.delete(:behavior)
      end
    end

    # validates a resource hash against its type schema
    def check_schema(resource, message_prefix = nil)
      namevars.each do |namevar|
        if resource[namevar].nil?
          raise Puppet::ResourceError, "`#{name}.get` did not return a value for the `#{namevar}` namevar attribute"
        end
      end

      message_prefix = 'Provider returned data that does not match the Type Schema' if message_prefix.nil?
      message = "#{message_prefix} for `#{name}[#{resource[namevars.first]}]`"

      rejected_keys = check_schema_keys(resource)
      bad_values = check_schema_values(resource)

      unless rejected_keys.empty?
        message += "\n Unknown attribute:\n"
        rejected_keys.each { |key, _value| message += "    * #{key}\n" }
      end
      unless bad_values.empty?
        message += "\n Value type mismatch:\n"
        bad_values.each { |key, value| message += "    * #{key}: #{value}\n" }
      end

      return if rejected_keys.empty? && bad_values.empty?

      notify_schema_errors(message)
    end

    def notify_schema_errors(message)
      if Puppet.settings[:strict] == :off
        Puppet.debug(message)
      elsif Puppet.settings[:strict] == :warning
        Puppet::ResourceApi.warning_count += 1
        Puppet.warning(message) if Puppet::ResourceApi.warning_count <= 100 # maximum number of schema warnings to display in a run
      elsif Puppet.settings[:strict] == :error
        raise Puppet::DevError, message
      end
    end

    # Returns an array of keys that where not found in the type schema
    # No longer modifies the resource passed in
    def check_schema_keys(resource)
      rejected = []
      resource.reject { |key| rejected << key if key != :title && attributes.key?(key) == false }
      rejected
    end

    # Returns a hash of keys and values that are not valid
    # does not modify the resource passed in
    def check_schema_values(resource)
      bad_vals = {}
      resource.each do |key, value|
        next unless attributes[key]
        type = @data_type_cache[attributes[key][:type]]
        is_sensitive = (attributes[key].key?(:sensitive) && (attributes[key][:sensitive] == true))
        error_message = Puppet::ResourceApi::DataTypeHandling.try_validate(
          type,
          value,
          '',
        )
        if is_sensitive
          bad_vals[key] = '<< redacted value >> ' + error_message unless error_message.nil?
        else
          bad_vals[key] = "#{value} (#{error_message})" unless error_message.nil?
        end
      end
      bad_vals
    end
  end
end
