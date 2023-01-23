# frozen_string_literal: true

require 'puppet/util'
require 'puppet/resource_api/parameter'

# Class containing read only parameter functionality for ResourceApi.
class Puppet::ResourceApi::ReadOnlyParameter < Puppet::ResourceApi::Parameter
  # This method raises error if the there is attempt to set value in parameter.
  # @return [Puppet::ResourceError] the error with information.
  def value=(value)
    raise Puppet::ResourceError,
          "Attempting to set `#{@attribute_name}` read_only attribute value " \
          "to `#{value}`"
  end

  # used internally
  # @returns the final mungified value of this parameter
  def rs_value
    @value
  end
end
