# frozen_string_literal: true

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# This module is responsible for setting default and alias values for the
# resource class.
module Puppet::ResourceApi::ValueCreator
  # This method is responsible for all setup of the value mapping for desired
  # resource class which can be Puppet::ResourceApi::Parameter,
  # Puppet::ResourceApi::ReadOnlyParameter, Puppet::ResourceApi::Property.
  # @param resource_class the class of selected resource to be extended
  # @param data_type the type instance
  # @param definition the definition of the property
  # @param options the ResourceAPI options hash containing setup information for
  # selected parameter or property
  def self.create_values(attribute_class, data_type, param_or_property, options = {})
    attribute_class.isnamevar if options[:behaviour] == :namevar

    # read-only values do not need type checking, but can have default values
    if options[:behaviour] != :read_only && options.key?(:default)
      if options[:default] == false
        # work around https://tickets.puppetlabs.com/browse/PUP-2368
        attribute_class.defaultto :false # rubocop:disable Lint/BooleanSymbol
      elsif options[:default] == true
        # work around https://tickets.puppetlabs.com/browse/PUP-2368
        attribute_class.defaultto :true # rubocop:disable Lint/BooleanSymbol
      else
        # marshal the default option to decouple that from the actual value.
        # we cache the dumped value in `marshalled`, but use a block to
        # unmarshal everytime the value is requested. Objects that can't be
        # marshalled
        # See https://stackoverflow.com/a/8206537/4918
        marshalled = Marshal.dump(options[:default])
        attribute_class.defaultto { Marshal.load(marshalled) } # rubocop:disable Security/MarshalLoad
      end
    end

    # provide hints to `puppet type generate` for better parsing
    if data_type.instance_of? Puppet::Pops::Types::POptionalType
      data_type = data_type.type
    end

    case data_type
    when Puppet::Pops::Types::PStringType
      # require any string value
      def_newvalues(attribute_class, param_or_property, %r{})
    when Puppet::Pops::Types::PBooleanType
      def_newvalues(attribute_class, param_or_property, 'true', 'false')
      attribute_class.aliasvalue true, 'true'
      attribute_class.aliasvalue false, 'false'
      attribute_class.aliasvalue :true, 'true' # rubocop:disable Lint/BooleanSymbol
      attribute_class.aliasvalue :false, 'false' # rubocop:disable Lint/BooleanSymbol
    when Puppet::Pops::Types::PIntegerType
      def_newvalues(attribute_class, param_or_property, %r{^-?\d+$})
    when Puppet::Pops::Types::PFloatType, Puppet::Pops::Types::PNumericType
      def_newvalues(attribute_class, param_or_property, Puppet::Pops::Patterns::NUMERIC)
    end

    case options[:type]
    when 'Enum[present, absent]'
      def_newvalues(attribute_class, param_or_property, 'absent', 'present')
    end
    attribute_class
  end

  # add the value to `this` property or param, depending on whether
  # param_or_property is `:newparam`, or `:newproperty`
  def self.def_newvalues(this, param_or_property, *values)
    if param_or_property == :newparam
      this.newvalues(*values)
    else
      values.each do |v|
        this.newvalue(v) {}
      end
    end
  end
end
