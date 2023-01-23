# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/config_node_complex_value'

class Hocon::Impl::ConfigNodeConcatenation
  include Hocon::Impl::ConfigNodeComplexValue
  def new_node(nodes)
    self.class.new(nodes)
  end
end