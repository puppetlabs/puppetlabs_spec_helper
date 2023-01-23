# frozen_string_literal: true

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# This module is used to handle data inside types, contains methods for munging
# and validation of the type values.
module Puppet::ResourceApi::DataTypeHandling
  # This method handles translating values from the runtime environment to the
  # expected types for the provider with validation.
  # When being called from `puppet resource`, it tries to transform the strings
  # from the command line into their expected ruby representations,
  # e.g. `"2"` (a string), will be transformed to `2` (the number)
  # if (and only if) the target `type` is `Integer`.
  # Additionally this function also validates that the passed in
  # (and optionally transformed) value matches the specified type.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check/clean
  # against.
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @param unpack_strings[Boolean] unpacking of strings for migrating off
  # legacy type
  # @return [type] the cleaned value
  def self.mungify(type, value, error_msg_prefix, unpack_strings = false)
    cleaned_value = mungify_core(
      type,
      value,
      error_msg_prefix,
      unpack_strings,
    )
    validate(type, cleaned_value, error_msg_prefix)
    cleaned_value
  end

  # This is core method used in mungify which handles translating values to expected
  # cleaned type values, result is not validated.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check/clean
  # against.
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @param unpack_strings[Boolean] unpacking of strings for migrating off
  # legacy type
  # @return [type] the cleaned value
  # @raise [Puppet::ResourceError] if `value` could not be parsed into `type`
  # @private
  def self.mungify_core(type, value, error_msg_prefix, unpack_strings = false)
    if unpack_strings
      # When the provider is exercised from the `puppet resource` CLI, we need
      # to unpack strings into the correct types, e.g. "1" (a string)
      # to 1 (an integer)
      cleaned_value, error_msg = try_mungify(type, value, error_msg_prefix)
      raise Puppet::ResourceError, error_msg if error_msg
      cleaned_value
    elsif value == :false # rubocop:disable Lint/BooleanSymbol
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      false
    elsif value == :true # rubocop:disable Lint/BooleanSymbol
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      true
    else
      # Every other time, we can use the values as is
      value
    end
  end

  # Recursive implementation part of #mungify_core. Uses a multi-valued return
  # value to avoid excessive exception throwing for regular usage.
  # @return [Array] if the mungify worked, the first element is the cleaned
  #   value, and the second element is nil. If the mungify failed, the first
  #   element is nil, and the second element is an error message
  # @private
  def self.try_mungify(type, value, error_msg_prefix)
    case type
    when Puppet::Pops::Types::PArrayType
      if value.is_a? Array
        conversions = value.map do |v|
          try_mungify(type.element_type, v, error_msg_prefix)
        end
        # only convert the values if none failed. otherwise fall through and
        # rely on puppet to render a proper error
        if conversions.all? { |c| c[1].nil? }
          value = conversions.map { |c| c[0] }
        end
      end
    when Puppet::Pops::Types::PBooleanType
      value = boolean_munge(value)
    when Puppet::Pops::Types::PIntegerType,
         Puppet::Pops::Types::PFloatType,
         Puppet::Pops::Types::PNumericType
      if value =~ %r{^-?\d+$} || value =~ Puppet::Pops::Patterns::NUMERIC
        value = Puppet::Pops::Utils.to_n(value)
      end
    when Puppet::Pops::Types::PEnumType,
         Puppet::Pops::Types::PStringType,
         Puppet::Pops::Types::PPatternType
      value = value.to_s if value.is_a? Symbol
    when Puppet::Pops::Types::POptionalType
      return value.nil? ? [nil, nil] : try_mungify(type.type, value, error_msg_prefix)
    when Puppet::Pops::Types::PVariantType
      # try converting to anything except string first
      string_type = type.types.find { |t| t.is_a? Puppet::Pops::Types::PStringType }
      conversion_results = (type.types - [string_type]).map do |t|
        try_mungify(t, value, error_msg_prefix)
      end

      # only consider valid results
      conversion_results = conversion_results.select { |r| r[1].nil? }.to_a

      # use the conversion result if unambiguous
      return conversion_results[0] if conversion_results.length == 1

      # return an error if ambiguous
      if conversion_results.length > 1
        return [nil, ambiguous_error_msg(error_msg_prefix, value, type)]
      end

      # try to interpret as string
      return try_mungify(string_type, value, error_msg_prefix) if string_type

      # fall through to default handling
    end

    error_msg = try_validate(type, value, error_msg_prefix)
    return [nil, error_msg] if error_msg # an error
    [value, nil]                         # match
  end

  # Returns correct boolean `value` based on one specified in `type`.
  # @param value the value to boolean munge
  # @private
  def self.boolean_munge(value)
    case value
    when 'true', :true # rubocop:disable Lint/BooleanSymbol
      true
    when 'false', :false # rubocop:disable Lint/BooleanSymbol
      false
    else
      value
    end
  end

  # Returns ambiguous error message based on `error_msg_prefix`, `value` and
  # `type`.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check against
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @private
  def self.ambiguous_error_msg(error_msg_prefix, value, type)
    "#{error_msg_prefix} #{value.inspect} is not unabiguously convertable to " \
    "#{type}"
  end

  # Validates the `value` against the specified `type`.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check against
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @raise [Puppet::ResourceError] if `value` is not of type `type`
  # @private
  def self.validate(type, value, error_msg_prefix)
    error_msg = try_validate(type, value, error_msg_prefix)
    raise Puppet::ResourceError, error_msg if error_msg
  end

  # Tries to validate the `value` against the specified `type`.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check against
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @return [String, nil] a error message indicating the problem, or `nil` if the value was valid.
  # @private
  def self.try_validate(type, value, error_msg_prefix)
    return nil if type.instance?(value)

    # an error :-(
    inferred_type = Puppet::Pops::Types::TypeCalculator.infer_set(value)
    error_msg = Puppet::Pops::Types::TypeMismatchDescriber.new.describe_mismatch(
      error_msg_prefix,
      type,
      inferred_type,
    )
    error_msg
  end

  def self.validate_ensure(definition)
    return unless definition[:attributes].key? :ensure
    options = definition[:attributes][:ensure]
    type = parse_puppet_type(:ensure, options[:type])

    return if type.is_a?(Puppet::Pops::Types::PEnumType) && type.values.sort == %w[absent present].sort
    raise Puppet::DevError, '`:ensure` attribute must have a type of: `Enum[present, absent]`'
  end

  def self.parse_puppet_type(attr_name, type)
    Puppet::Pops::Types::TypeParser.singleton.parse(type)
  rescue Puppet::ParseErrorWithIssue => e
    raise Puppet::DevError, "The type of the `#{attr_name}` attribute " \
          "`#{type}` could not be parsed: #{e.message}"
  rescue Puppet::ParseError => e
    raise Puppet::DevError, "The type of the `#{attr_name}` attribute " \
          "`#{type}` is not recognised: #{e.message}"
  end
end
