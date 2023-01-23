# frozen_string_literal: true

require 'pathname'
require 'puppet/resource_api/data_type_handling'
require 'puppet/resource_api/glue'
require 'puppet/resource_api/parameter'
require 'puppet/resource_api/property'
require 'puppet/resource_api/puppet_context' unless RUBY_PLATFORM == 'java'
require 'puppet/resource_api/read_only_parameter'
require 'puppet/resource_api/transport'
require 'puppet/resource_api/transport/wrapper'
require 'puppet/resource_api/type_definition'
require 'puppet/resource_api/value_creator'
require 'puppet/resource_api/version'
require 'puppet/type'
require 'puppet/util/network_device'

# This module contains the main API to register and access types, providers and transports.
module Puppet::ResourceApi
  @warning_count = 0

  class << self
    attr_accessor :warning_count
  end

  def register_type(definition)
    # Attempt to create a TypeDefinition from the input hash
    # This will validate and throw if its not right
    type_def = TypeDefinition.new(definition)

    # prepare the ruby module for the provider
    # this has to happen before Puppet::Type.newtype starts autoloading providers
    # it also needs to be guarded against the namespace already being defined by something
    # else to avoid ruby warnings
    unless Puppet::Provider.const_defined?(class_name_from_type_name(definition[:name]), false)
      Puppet::Provider.const_set(class_name_from_type_name(definition[:name]), Module.new)
    end

    Puppet::Type.newtype(definition[:name].to_sym) do
      # The :desc value is already cleaned up by the TypeDefinition validation
      @doc = definition[:desc]
      @type_definition = type_def

      # Keeps a copy of the provider around. Weird naming to avoid clashes with puppet's own `provider` member
      define_singleton_method(:my_provider) do
        @my_provider ||= Hash.new { |hash, key| hash[key] = Puppet::ResourceApi.load_provider(definition[:name]).new }

        if Puppet::Util::NetworkDevice.current.is_a? Puppet::ResourceApi::Transport::Wrapper
          @my_provider[Puppet::Util::NetworkDevice.current.transport.class]
        else
          @my_provider[Puppet::Util::NetworkDevice.current.class]
        end
      end

      # make the provider available in the instance's namespace
      def my_provider
        self.class.my_provider
      end

      define_singleton_method(:type_definition) do
        @type_definition
      end

      def type_definition
        self.class.type_definition
      end

      if type_definition.feature?('remote_resource')
        apply_to_device
      end

      def initialize(attributes)
        # $stderr.puts "A: #{attributes.inspect}"
        if attributes.is_a? Puppet::Resource
          @title = attributes.title
          @catalog = attributes.catalog
          sensitives = attributes.sensitive_parameters
          attributes = attributes.to_hash
        else
          @ral_find_absent = true
          sensitives = []
        end

        # undo puppet's unwrapping of Sensitive values to provide a uniform experience for providers
        # See https://tickets.puppetlabs.com/browse/PDK-1091 for investigation and background
        sensitives.each do |name|
          if attributes.key?(name) && !attributes[name].is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
            attributes[name] = Puppet::Pops::Types::PSensitiveType::Sensitive.new(attributes[name])
          end
        end

        # $stderr.puts "B: #{attributes.inspect}"
        if type_definition.feature?('canonicalize')
          attributes = my_provider.canonicalize(context, [attributes])[0]
        end

        # the `Puppet::Resource::Ral.find` method, when `instances` does not return a match, uses a Hash with a `:name` key to create
        # an "absent" resource. This is often hit by `puppet resource`. This needs to work, even if the namevar is not called `name`.
        # This bit here relies on the default `title_patterns` (see below) to match the title back to the first (and often only) namevar
        if type_definition.attributes[:name].nil? && attributes[:title].nil?
          attributes[:title] = attributes.delete(:name)
          if attributes[:title].nil? && !type_definition.namevars.empty?
            attributes[:title] = @title
          end
        end

        super(attributes)
      end

      def name
        title
      end

      def self.build_title(type_definition, resource_hash)
        if type_definition.namevars.size > 1
          # use a MonkeyHash to allow searching in Puppet's RAL
          Puppet::ResourceApi::MonkeyHash[type_definition.namevars.map { |attr| [attr, resource_hash[attr]] }]
        else
          resource_hash[type_definition.namevars[0]]
        end
      end

      def rsapi_title
        @rsapi_title ||= self.class.build_title(type_definition, self)
        @rsapi_title
      end

      def rsapi_canonicalized_target_state
        @rsapi_canonicalized_target_state ||= begin
          # skip puppet's injected metaparams
          actual_params = @parameters.select { |k, _v| type_definition.attributes.key? k }
          target_state = Hash[actual_params.map { |k, v| [k, v.rs_value] }]
          target_state = my_provider.canonicalize(context, [target_state]).first if type_definition.feature?('canonicalize')
          target_state
        end
        @rsapi_canonicalized_target_state
      end

      def rsapi_current_state
        refresh_current_state unless @rsapi_current_state
        @rsapi_current_state
      end

      def to_resource
        to_resource_shim(super)
      end

      def to_resource_shim(resource)
        resource_hash = Hash[resource.keys.map { |k| [k, resource[k]] }]
        resource_hash[:title] = resource.title
        ResourceShim.new(resource_hash, type_definition.name, type_definition.namevars, type_definition.attributes, catalog)
      end

      validate do
        # enforce mandatory attributes
        @missing_attrs = []
        @missing_params = []

        # do not validate on known-absent instances
        return if @ral_find_absent

        definition[:attributes].each do |name, options|
          type = Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
            :name,
            options[:type],
          )

          # skip read only vars and the namevar
          next if [:read_only, :namevar].include? options[:behaviour]

          # skip properties if the resource is being deleted
          next if definition[:attributes][:ensure] &&
                  value(:ensure) == 'absent' &&
                  options[:behaviour].nil?

          if value(name).nil? && !(type.instance_of? Puppet::Pops::Types::POptionalType)
            @missing_attrs << name
            @missing_params << name if options[:behaviour] == :parameter
          end
        end

        @missing_attrs -= [:ensure]

        raise_missing_params if @missing_params.any?
      end

      # If the custom_insync feature is specified but no insyncable attributes are included
      # in the definition, add the hidden rsapi_custom_insync_trigger property.
      # This property exists *only* to allow a resource without properties to still execute an
      # insync check; there's no point in specifying it in a manifest as it can only have one
      # value; it cannot be specified in a type definition as it should only exist in this case.
      if type_definition.feature?('custom_insync') && type_definition.insyncable_attributes.empty?
        custom_insync_trigger_options = {
          type: 'Enum[do_not_specify_in_manifest]',
          desc: 'A hidden property which enables a type with custom insync to perform an insync check without specifying any insyncable properties',
          default: 'do_not_specify_in_manifest',
        }

        type_definition.create_attribute_in(self, :rsapi_custom_insync_trigger, :newproperty, Puppet::ResourceApi::Property, custom_insync_trigger_options)
      end

      definition[:attributes].each do |name, options|
        # puts "#{name}: #{options.inspect}"

        if options[:behaviour]
          unless [:read_only, :namevar, :parameter, :init_only].include? options[:behaviour]
            raise Puppet::ResourceError, "`#{options[:behaviour]}` is not a valid behaviour value"
          end
        end

        # TODO: using newparam everywhere would suppress change reporting
        #       that would allow more fine-grained reporting through context,
        #       but require more invest in hooking up the infrastructure to emulate existing data
        if [:parameter, :namevar].include? options[:behaviour]
          param_or_property = :newparam
          parent = Puppet::ResourceApi::Parameter
        elsif options[:behaviour] == :read_only
          param_or_property = :newparam
          parent = Puppet::ResourceApi::ReadOnlyParameter
        else
          param_or_property = :newproperty
          parent = Puppet::ResourceApi::Property
        end

        type_definition.create_attribute_in(self, name, param_or_property, parent, options)
      end

      def self.instances
        # puts 'instances'
        # force autoloading of the provider
        provider(type_definition.name)

        initial_fetch = if type_definition.feature?('simple_get_filter')
                          my_provider.get(context, [])
                        else
                          my_provider.get(context)
                        end

        initial_fetch.map do |resource_hash|
          type_definition.check_schema(resource_hash)
          # allow a :title from the provider to override the default
          result = if resource_hash.key? :title
                     new(title: resource_hash[:title])
                   else
                     new(title: build_title(type_definition, resource_hash))
                   end
          result.cache_current_state(resource_hash)
          result
        end
      end

      def refresh_current_state
        @rsapi_current_state = if type_definition.feature?('simple_get_filter')
                                 my_provider.get(context, [rsapi_title]).find { |h| namevar_match?(h) }
                               else
                                 my_provider.get(context).find { |h| namevar_match?(h) }
                               end

        if @rsapi_current_state
          type_definition.check_schema(@rsapi_current_state)
          strict_check(@rsapi_current_state)
        else
          @rsapi_current_state = if rsapi_title.is_a? Hash
                                   rsapi_title.dup
                                 else
                                   { title: rsapi_title }
                                 end
          @rsapi_current_state[:ensure] = :absent if type_definition.ensurable?
        end
      end

      # Use this to set the current state from the `instances` method
      def cache_current_state(resource_hash)
        @rsapi_current_state = resource_hash
        strict_check(@rsapi_current_state)
      end

      def retrieve
        Puppet.debug("Current State: #{rsapi_current_state.inspect}")

        result = Puppet::Resource.new(self.class, title, parameters: rsapi_current_state)
        # puppet needs ensure to be a symbol
        result[:ensure] = result[:ensure].to_sym if type_definition.ensurable? && result[:ensure].is_a?(String)

        raise_missing_attrs

        result
      end

      def namevar_match?(item)
        context.type.namevars.all? do |namevar|
          item[namevar] == @parameters[namevar].value if @parameters[namevar].respond_to? :value
        end
      end

      def flush
        raise_missing_attrs

        # puts 'flush'
        target_state = rsapi_canonicalized_target_state

        retrieve unless @rsapi_current_state

        return if @rsapi_current_state == target_state

        Puppet.debug("Target State: #{target_state.inspect}")

        # enforce init_only attributes
        if Puppet.settings[:strict] != :off && @rsapi_current_state && (@rsapi_current_state[:ensure] == 'present' && target_state[:ensure] == 'present')
          target_state.each do |name, value|
            next unless type_definition.attributes[name][:behaviour] == :init_only && value != @rsapi_current_state[name]
            message = "Attempting to change `#{name}` init_only attribute value from `#{@rsapi_current_state[name]}` to `#{value}`"
            case Puppet.settings[:strict]
            when :warning
              Puppet.warning(message)
            when :error
              raise Puppet::ResourceError, message
            end
          end
        end

        if type_definition.feature?('supports_noop')
          my_provider.set(context, { rsapi_title => { is: @rsapi_current_state, should: target_state } }, noop: noop?)
        else
          my_provider.set(context, rsapi_title => { is: @rsapi_current_state, should: target_state }) unless noop?
        end
        if context.failed?
          context.reset_failed
          raise 'Execution encountered an error'
        end

        # remember that we have successfully reached our desired state
        @rsapi_current_state = target_state
      end

      def raise_missing_attrs
        error_msg = "The following mandatory attributes were not provided:\n    *  " + @missing_attrs.join(", \n    *  ")
        raise Puppet::ResourceError, error_msg if @missing_attrs.any? && (value(:ensure) != :absent && !value(:ensure).nil?)
      end

      def raise_missing_params
        error_msg = "The following mandatory parameters were not provided:\n    *  " + @missing_params.join(", \n    *  ")
        raise Puppet::ResourceError, error_msg
      end

      def strict_check(current_state)
        return if Puppet.settings[:strict] == :off

        strict_check_canonicalize(current_state) if type_definition.feature?('canonicalize')
        strict_check_title_parameter(current_state) if type_definition.namevars.size > 1 && !type_definition.title_patterns.empty?

        nil
      end

      def strict_message(message)
        case Puppet.settings[:strict]
        when :warning
          Puppet.warning(message)
        when :error
          raise Puppet::DevError, message
        end
      end

      def strict_check_canonicalize(current_state)
        # if strict checking is on we must notify if the values are changed by canonicalize
        # make a deep copy to perform the operation on and to compare against later
        state_clone = Marshal.load(Marshal.dump(current_state))
        state_clone = my_provider.canonicalize(context, [state_clone]).first

        # compare the clone against the current state to see if changes have been made by canonicalize
        return unless state_clone && (current_state != state_clone)

        #:nocov:
        # codecov fails to register this multiline as covered, even though simplecov does.
        message = <<MESSAGE.strip
#{type_definition.name}[#{@title}]#get has not provided canonicalized values.
Returned values:       #{current_state.inspect}
Canonicalized values:  #{state_clone.inspect}
MESSAGE
        #:nocov:
        strict_message(message)
      end

      def strict_check_title_parameter(current_state)
        unless current_state.key?(:title)
          strict_message("#{type_definition.name}[#{@title}]#get has not provided a title attribute.")
          return
        end

        # Logic borrowed from Puppet::Resource.parse_title
        title_hash = {}
        self.class.title_patterns.each do |regexp, symbols|
          captures = regexp.match(current_state[:title])
          next if captures.nil?
          symbols.zip(captures[1..-1]).each do |symbol_and_lambda, capture|
            # The Resource API does not support passing procs in title_patterns
            # so, unlike Puppet::Resource, we do not need to handle that here.
            symbol = symbol_and_lambda[0]
            title_hash[symbol] = capture
          end
          break
        end

        return if title_hash == rsapi_title

        namevars = type_definition.namevars.reject { |namevar| title_hash[namevar] == rsapi_title[namevar] }

        #:nocov:
        # codecov fails to register this multiline as covered, even though simplecov does.
        message = <<MESSAGE.strip
#{type_definition.name}[#{@title}]#get has provided a title attribute which does not match all namevars.
Namevars which do not match: #{namevars.inspect}
Returned parsed title hash:  #{title_hash.inspect}
Expected hash:               #{rsapi_title.inspect}
MESSAGE
        #:nocov:
        strict_message(message)
      end

      define_singleton_method(:context) do
        @context ||= PuppetContext.new(TypeDefinition.new(definition))
      end

      def context
        self.class.context
      end

      def self.title_patterns
        @title_patterns ||= if type_definition.definition.key? :title_patterns
                              parse_title_patterns(type_definition.definition[:title_patterns])
                            else
                              [[%r{(.*)}m, [[type_definition.namevars.first]]]]
                            end
      end

      # Creates a `title_pattern` compatible data structure to pass to the underlying puppet runtime environment.
      # It uses the named items in the regular expression to connect the dots
      #
      # @example `[ %r{^(?<package>.*[^-])-(?<manager>.*)$} ]` becomes
      #   [
      #     [
      #       %r{^(?<package>.*[^-])-(?<manager>.*)$},
      #       [ [:package], [:manager] ]
      #     ],
      #   ]
      def self.parse_title_patterns(patterns)
        patterns.map do |item|
          regex = Regexp.new(item[:pattern])
          [item[:pattern], regex.names.map { |x| [x.to_sym] }]
        end
      end

      [:autorequire, :autobefore, :autosubscribe, :autonotify].each do |auto|
        next unless definition[auto]

        definition[auto].each do |type, values|
          Puppet.debug("Registering #{auto} for #{type}: #{values.inspect}")
          send(auto, type.downcase.to_sym) do
            [values].flatten.map do |v|
              match = %r{\A\$(.*)\Z}.match(v) if v.is_a? String
              if match.nil?
                v
              else
                self[match[1].to_sym]
              end
            end
          end
        end
      end
    end
  end
  module_function :register_type # rubocop:disable Style/AccessModifierDeclarations

  def load_provider(type_name)
    class_name = class_name_from_type_name(type_name)
    type_name_sym = type_name.to_sym
    device_name = if Puppet::Util::NetworkDevice.current.nil?
                    nil
                  elsif Puppet::Util::NetworkDevice.current.is_a? Puppet::ResourceApi::Transport::Wrapper
                    # extract the device type from the currently loaded device's class
                    Puppet::Util::NetworkDevice.current.schema.name
                  else
                    Puppet::Util::NetworkDevice.current.class.name.split('::')[-2].downcase
                  end
    device_class_name = class_name_from_type_name(device_name)

    if device_name
      device_name_sym = device_name.to_sym if device_name
      load_device_provider(class_name, type_name_sym, device_class_name, device_name_sym)
    else
      load_default_provider(class_name, type_name_sym)
    end
  rescue NameError
    if device_name # line too long # rubocop:disable Style/GuardClause
      raise Puppet::DevError, "Found neither the device-specific provider class Puppet::Provider::#{class_name}::#{device_class_name} in puppet/provider/#{type_name}/#{device_name}"\
      " nor the generic provider class Puppet::Provider::#{class_name}::#{class_name} in puppet/provider/#{type_name}/#{type_name}"
    else
      raise Puppet::DevError, "provider class Puppet::Provider::#{class_name}::#{class_name} not found in puppet/provider/#{type_name}/#{type_name}"
    end
  end
  module_function :load_provider # rubocop:disable Style/AccessModifierDeclarations

  def load_default_provider(class_name, type_name_sym)
    # loads the "puppet/provider/#{type_name}/#{type_name}" file through puppet
    Puppet::Type.type(type_name_sym).provider(type_name_sym)
    Puppet::Provider.const_get(class_name, false).const_get(class_name, false)
  end
  module_function :load_default_provider # rubocop:disable Style/AccessModifierDeclarations

  def load_device_provider(class_name, type_name_sym, device_class_name, device_name_sym)
    # loads the "puppet/provider/#{type_name}/#{device_name}" file through puppet
    Puppet::Type.type(type_name_sym).provider(device_name_sym)
    provider_module = Puppet::Provider.const_get(class_name, false)
    if provider_module.const_defined?(device_class_name, false)
      provider_module.const_get(device_class_name, false)
    else
      load_default_provider(class_name, type_name_sym)
    end
  end
  module_function :load_device_provider # rubocop:disable Style/AccessModifierDeclarations

  # keeps the existing register API format. e.g. Puppet::ResourceApi.register_type
  def register_transport(schema)
    Puppet::ResourceApi::Transport.register(schema)
  end
  module_function :register_transport # rubocop:disable Style/AccessModifierDeclarations

  def self.class_name_from_type_name(type_name)
    type_name.to_s.split('_').map(&:capitalize).join
  end

  def self.caller_is_resource_app?
    caller.any? { |c| c.match(%r{application/resource.rb:}) }
  end
end
