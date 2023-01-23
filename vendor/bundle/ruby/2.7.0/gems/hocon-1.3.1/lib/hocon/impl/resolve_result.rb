# encoding: utf-8

require 'hocon'
require 'hocon/impl'

# value is allowed to be null
class Hocon::Impl::ResolveResult
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError

  attr_accessor :context, :value

  def initialize(context, value)
    @context = context
    @value = value
  end

  def self.make(context, value)
    self.new(context, value)
  end

  def as_object_result
    unless @value.is_a?(Hocon::Impl::AbstractConfigObject)
      raise ConfigBugOrBrokenError.new("Expecting a resolve result to be an object, but it was #{@value}")
    end
    self
  end

  def as_value_result
    self
  end

  def pop_trace
    self.class.make(@context.pop_trace, value)
  end

  def to_s
    "ResolveResult(#{@value})"
  end
end
