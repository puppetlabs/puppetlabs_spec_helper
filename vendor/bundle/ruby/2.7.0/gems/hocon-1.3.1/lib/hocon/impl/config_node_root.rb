# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/config_node_array'
require 'hocon/impl/config_node_complex_value'
require 'hocon/impl/config_node_object'

class Hocon::Impl::ConfigNodeRoot
  include Hocon::Impl::ConfigNodeComplexValue
  def initialize(children, origin)
    super(children)
    @origin = origin
  end

  def new_node(nodes)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "Tried to indent the root object"
  end

  def value
    @children.each do |node|
      if node.is_a?(Hocon::Impl::ConfigNodeComplexValue)
        return node
      end
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "ConfigNodeRoot did not contain a value"
  end

  def set_value(desired_path, value, flavor)
    children_copy = @children.clone
    children_copy.each_with_index do |node, index|
      if node.is_a?(Hocon::Impl::ConfigNodeComplexValue)
        if node.is_a?(Hocon::Impl::ConfigNodeArray)
          raise Hocon::ConfigError::ConfigBugOrBrokenError, "The ConfigDocument had an array at the root level, and values cannot be modified inside an array."
        elsif node.is_a?(Hocon::Impl::ConfigNodeObject)
          if value.nil?
            children_copy[index] = node.remove_value_on_path(desired_path, flavor)
          else
            children_copy[index] = node.set_value_on_path(desired_path, value, flavor)
          end
          return self.class.new(children_copy, @origin)
        end
      end
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "ConfigNodeRoot did not contain a value"
  end

  def has_value(desired_path)
    path = Hocon::Impl::PathParser.parse_path(desired_path)
    @children.each do |node|
      if node.is_a?(Hocon::Impl::ConfigNodeComplexValue)
        if node.is_a?(Hocon::Impl::ConfigNodeArray)
          raise Hocon::ConfigError::ConfigBugOrBrokenError, "The ConfigDocument had an array at the root level, and values cannot be modified inside an array."
        elsif node.is_a?(Hocon::Impl::ConfigNodeObject)
          return node.has_value(path)
        end
      end
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "ConfigNodeRoot did not contain a value"
  end
end
