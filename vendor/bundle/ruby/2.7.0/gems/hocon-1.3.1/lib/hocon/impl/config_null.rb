# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_value_type'

class Hocon::Impl::ConfigNull
  include Hocon::Impl::AbstractConfigValue

  def initialize(origin)
    super(origin)
  end

  def value_type
    Hocon::ConfigValueType::NULL
  end

  def unwrapped
    nil
  end

  def transform_to_string
    "null"
  end

  def render_value_to_sb(sb, indent, at_root, options)
    sb << "null"
  end

  def new_copy(origin)
    self.class.new(origin)
  end

end
