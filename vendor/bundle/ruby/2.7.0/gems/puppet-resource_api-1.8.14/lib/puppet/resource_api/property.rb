# frozen_string_literal: true

require 'puppet/util'
require 'puppet/property'

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# Class containing property functionality for ResourceApi.
class Puppet::ResourceApi::Property < Puppet::Property
  # This initialize takes arguments and sets up new property.
  # @param type_name the name of the Puppet Type
  # @param data_type the data type of property instance
  # @param attribute_name the name of attribue of the property
  # @param resource_hash the resource hash instance which is passed to the
  # parent class.
  def initialize(type_name, data_type, attribute_name, resource_hash, referrable_type = nil)
    @type_name = type_name
    @data_type = data_type
    @attribute_name = attribute_name
    @resource = resource_hash[:resource]
    @referrable_type = referrable_type

    # Do not want to define insync on the base class because
    # this overrides for everything instead of only for the
    # appropriate instance/class of the property.
    if self.class != Puppet::ResourceApi::Property
      # Define class method insync?(is) if the custom_insync feature flag is set
      if referrable_type&.type_definition&.feature?('custom_insync')
        def_custom_insync?
        if @attribute_name == :rsapi_custom_insync_trigger
          @change_to_s_value = 'Custom insync logic determined that this resource is out of sync'
        end
      # Define class method insync?(is) if the name is :ensure and custom_insync feature flag is not set
      elsif @attribute_name == :ensure
        def_ensure_insync?
      end
    end

    # Pass resource to parent Puppet class.
    super(**resource_hash)
  end

  # This method returns value of the property.
  # @return [type] the property value
  def should
    if @attribute_name == :ensure && rs_value.is_a?(String)
      rs_value.to_sym
    elsif rs_value == false
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      :false # rubocop:disable Lint/BooleanSymbol
    elsif rs_value == true
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      :true # rubocop:disable Lint/BooleanSymbol
    else
      rs_value
    end
  end

  # This method sets and returns value of the property and sets @shouldorig.
  # @param value the value to be set and clean
  # @return [type] the property value
  def should=(value)
    @shouldorig = value

    if @attribute_name == :ensure
      value = value.to_s
    end

    # Puppet requires the @should value to always be stored as an array. We do not use this
    # for anything else
    # @see Puppet::Property.should=(value)
    @should = [
      Puppet::ResourceApi::DataTypeHandling.mungify(
        @data_type,
        value,
        "#{@type_name}.#{@attribute_name}",
        Puppet::ResourceApi.caller_is_resource_app?,
      ),
    ]
  end

  # used internally
  # @returns the final mungified value of this property
  def rs_value
    @should ? @should.first : @should
  end

  # method overloaded only for the :ensure property, add option to check if the
  # rs_value matches is. Only if the class is child of
  # Puppet::ResourceApi::Property.
  def def_ensure_insync?
    define_singleton_method(:insync?) { |is| rs_value.to_s == is.to_s }
  end

  def def_custom_insync?
    define_singleton_method(:insync?) do |is|
      provider    = @referrable_type.my_provider
      context     = @referrable_type.context
      should_hash = @resource.rsapi_canonicalized_target_state
      is_hash     = @resource.rsapi_current_state
      title       = @resource.rsapi_title

      raise(Puppet::DevError, 'No insync? method defined in the provider; an insync? method must be defined if the custom_insync feature is defined for the type') unless provider.respond_to?(:insync?)

      provider_insync_result, change_message = provider.insync?(context, title, @attribute_name, is_hash, should_hash)

      unless provider_insync_result.nil? || change_message.nil? || change_message.empty?
        @change_to_s_value = change_message
      end

      case provider_insync_result
      when nil
        # If validating ensure and no custom insync was used, check if rs_value matches is.
        return rs_value.to_s == is.to_s if @attribute_name == :ensure
        # Otherwise, super and rely on Puppet::Property.insync?
        super(is)
      when TrueClass, FalseClass
        return provider_insync_result
      else
        # When returning anything else, raise a DevError for a non-idiomatic return
        raise(Puppet::DevError, "Custom insync for #{@attribute_name} returned a #{provider_insync_result.class} with a value of #{provider_insync_result.inspect} instead of true/false; insync? MUST return nil or the boolean true or false") # rubocop:disable Metrics/LineLength
      end
    end

    define_singleton_method(:change_to_s) do |current_value, newvalue|
      # As defined in the custom insync? method, it is sometimes useful to overwrite the default change messaging;
      # The enables a user to return a more useful change report than a strict "is to should" report.
      # If @change_to_s_value is not set, Puppet writes a generic change notification, like:
      #   Notice: /Stage[main]/Main/<type_name>[<name_hash>]/<property name>: <property name> changed <is value> to <should value>
      # If #change_to_s_value is *nil* Puppet writes a weird empty message like:
      #   Notice: /Stage[main]/Main/<type_name>[<name_hash>]/<property name>:
      @change_to_s_value || super(current_value, newvalue)
    end
  end

  # puppet symbolizes some values through puppet/parameter/value.rb
  # (see .convert()), but (especially) Enums are strings. specifying a
  # munge block here skips the value_collection fallback in
  # puppet/parameter.rb's default .unsafe_munge() implementation.
  munge { |v| v }

  # stop puppet from trying to call into the provider when
  # no pre-defined values have been specified
  # "This is not the provider you are looking for." -- Obi-Wan Kaniesobi.
  def call_provider(_value); end
end
