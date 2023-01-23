# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/simple_includer'
require 'hocon/config_include_context'
require 'hocon/impl/config_impl'

class Hocon::Impl::SimpleIncludeContext
  include Hocon::ConfigIncludeContext

  def initialize(parseable)
    @parseable = parseable
  end

  def with_parseable(parseable)
    if parseable.equal?(@parseable)
      self
    else
      self.class.new(parseable)
    end
  end

  def relative_to(filename)
    if Hocon::Impl::ConfigImpl.trace_loads_enabled
      Hocon::Impl::ConfigImpl.trace("Looking for '#{filename}' relative to #{@parseable}")
    end
    if ! @parseable.nil?
      @parseable.relative_to(filename)
    else
      nil
    end
  end

  def parse_options
    Hocon::Impl::SimpleIncluder.clear_for_include(@parseable.options)
  end
end
