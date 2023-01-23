# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_value'
require 'hocon/config_value_type'
require 'hocon/impl/config_impl_util'

class Hocon::Impl::ConfigString
  include Hocon::Impl::AbstractConfigValue

  ConfigImplUtil = Hocon::Impl::ConfigImplUtil

  attr_reader :value

  class Quoted < Hocon::Impl::ConfigString
    def initialize(origin, value)
      super(origin, value)
    end

    def new_copy(origin)
      self.class.new(origin, @value)
    end

    private

    # serialization all goes through SerializedConfigValue
    def write_replace
      Hocon::Impl::SerializedConfigValue.new(self)
    end
  end

  # this is sort of a hack; we want to preserve whether whitespace
  # was quoted until we process substitutions, so we can ignore
  # unquoted whitespace when concatenating lists or objects.
  # We dump this distinction when serializing and deserializing,
  # but that 's OK because it isn' t in equals/hashCode, and we
  # don 't allow serializing unresolved objects which is where
  # quoted-ness matters. If we later make ConfigOrigin point
  # to the original token range, we could use that to implement
  # wasQuoted()
  class Unquoted < Hocon::Impl::ConfigString
    def initialize(origin, value)
      super(origin, value)
    end

    def new_copy(origin)
      self.class.new(origin, @value)
    end

    def write_replace
      Hocon::Impl::SerializedConfigValue.new(self)
    end
  end

  def was_quoted?
    self.is_a?(Quoted)
  end

  def value_type
    Hocon::ConfigValueType::STRING
  end

  def unwrapped
    @value
  end

  def transform_to_string
    @value
  end

  def render_value_to_sb(sb, indent_size, at_root, options)
    if options.json?
      sb << ConfigImplUtil.render_json_string(@value)
    else
      sb << ConfigImplUtil.render_string_unquoted_if_possible(@value)
    end
  end

  private

  def initialize(origin, value)
    super(origin)
    @value = value
  end
end
