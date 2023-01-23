# frozen_string_literal: true

require 'puppet/util'
require 'puppet/parameter'

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# Class containing parameter functionality for ResourceApi.
class Puppet::ResourceApi::Parameter < Puppet::Parameter
  attr_reader :value

  # This initialize takes arguments and sets up new parameter.
  # @param type_name the name of the Puppet Type
  # @param data_type the data type of parameter instance
  # @param attribute_name the name of attribue of the parameter
  # @param resource_hash the resource hash instance which is passed to the
  # parent class.
  def initialize(type_name, data_type, attribute_name, resource_hash, _referrable_type = nil)
    @type_name = type_name
    @data_type = data_type
    @attribute_name = attribute_name
    super(**resource_hash) # Pass resource to parent Puppet class.
  end

  # This method assigns value to the parameter and cleans value.
  # @param value the value to be set and clean
  # @return [type] the cleaned value
  def value=(value)
    @value = Puppet::ResourceApi::DataTypeHandling.mungify(
      @data_type,
      value,
      "#{@type_name}.#{@attribute_name}",
      Puppet::ResourceApi.caller_is_resource_app?,
    )
  end

  # used internally
  # @returns the final mungified value of this parameter
  def rs_value
    @value
  end

  # puppet symbolizes some values through puppet/parameter/value.rb
  # (see .convert()), but (especially) Enums are strings. specifying a
  # munge block here skips the value_collection fallback in
  # puppet/parameter.rb's default .unsafe_munge() implementation.
  munge { |v| v }
end
