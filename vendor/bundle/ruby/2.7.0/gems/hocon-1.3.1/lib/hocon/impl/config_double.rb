# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/config_number'

class Hocon::Impl::ConfigDouble < Hocon::Impl::ConfigNumber
  def initialize(origin, value, original_text)
    super(origin, original_text)
    @value = value
  end

  attr_reader :value

  def value_type
    Hocon::ConfigValueType::NUMBER
  end

  def unwrapped
    @value
  end

  def transform_to_string
    s = super
    if s.nil?
      @value.to_s
    else
      s
    end
  end

  def long_value
    @value.to_i
  end

  def double_value
    @value
  end

  def new_copy(origin)
    self.class.new(origin, @value, original_text)
  end

  # NOTE: skipping `writeReplace` from upstream, because it involves serialization
end
