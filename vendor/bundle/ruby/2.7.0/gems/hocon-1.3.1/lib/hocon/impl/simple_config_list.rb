# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/resolve_status'
require 'hocon/config_value_type'
require 'hocon/config_error'
require 'hocon/impl/abstract_config_object'
require 'forwardable'
require 'hocon/impl/unsupported_operation_error'
require 'hocon/impl/resolve_result'
require 'hocon/impl/container'
require 'hocon/config_list'

class Hocon::Impl::SimpleConfigList
  include Hocon::Impl::Container
  include Hocon::ConfigList
  include Hocon::Impl::AbstractConfigValue
  extend Forwardable

  ResolveStatus = Hocon::Impl::ResolveStatus
  ResolveResult = Hocon::Impl::ResolveResult
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError

  def initialize(origin, value, status = ResolveStatus.from_values(value))
    super(origin)
    @value = value
    @resolved = (status == ResolveStatus::RESOLVED)

    # kind of an expensive debug check (makes this constructor pointless)
    if status != ResolveStatus.from_values(value)
      raise ConfigBugOrBrokenError, "SimpleConfigList created with wrong resolve status: #{self}"
    end
  end

  attr_reader :value

  def_delegators :@value, :[], :include?, :empty?, :size, :index, :rindex, :each, :map

  def value_type
    Hocon::ConfigValueType::LIST
  end

  def unwrapped
    @value.map { |v| v.unwrapped }
  end

  def resolve_status
    ResolveStatus.from_boolean(@resolved)
  end

  def replace_child(child, replacement)
    new_list = replace_child_in_list(@value, child, replacement)
    if new_list.nil?
      nil
    else
      # we use the constructor flavor that will recompute the resolve status
      SimpleConfigList.new(origin, new_list)
    end
  end

  def has_descendant?(descendant)
    Hocon::Impl::AbstractConfigValue.has_descendant_in_list?(@value, descendant)
  end

  def modify(modifier, new_resolve_status)
    begin
      modify_may_throw(modifier, new_resolve_status)
    rescue Hocon::ConfigError => e
      raise e
    end
  end

  def modify_may_throw(modifier, new_resolve_status)
    # lazy-create for optimization
    changed = nil
    i = 0
    @value.each { |v|
      modified = modifier.modify_child_may_throw(nil, v)

      # lazy-create the new list if required
      if changed == nil && !modified.equal?(v)
        changed = []
        j = 0
        while j < i
          changed << @value[j]
          j += 1
        end
      end

      # once the new list is created, all elements
      # have to go in it.if modifyChild returned
      # null, we drop that element.
      if changed != nil && modified != nil
        changed << modified
      end

      i += 1
    }

    if changed != nil
      if new_resolve_status != nil
        self.class.new(origin, changed, new_resolve_status)
      else
        self.class.new(origin, changed)
      end
    else
      self
    end
  end

  class ResolveModifier
    attr_reader :context, :source
    def initialize(context, source)
      @context = context
      @source = source
    end

    def modify_child_may_throw(key, v)
      result = @context.resolve(v, source)
      @context = result.context
      result.value
    end
  end

  def resolve_substitutions(context, source)
    if @resolved
      return Hocon::Impl::ResolveResult.make(context, self)
    end

    if context.is_restricted_to_child
      # if a list restricts to a child path, then it has no child paths,
      # so nothing to do.
      Hocon::Impl::ResolveResult.make(context, self)
    else
      begin
        modifier = ResolveModifier.new(context, source.push_parent(self))
        value = modify_may_throw(modifier, context.options.allow_unresolved ? nil : ResolveStatus::RESOLVED)
        Hocon::Impl::ResolveResult.make(modifier.context, value)
      rescue NotPossibleToResolve => e
        raise e
      rescue RuntimeError => e
        raise e
      rescue Exception => e
        raise ConfigBugOrBrokenError.new("unexpected exception", e)
      end
    end
  end

  def relativized(prefix)
    modifier = Class.new do
      include Hocon::Impl::AbstractConfigValue::NoExceptionsModifier

      # prefix isn't in scope inside of a def, but it is in scope inside of Class.new
      # so manually define a method that has access to prefix
      # I feel dirty
      define_method(:modify_child) do |key, v|
        v.relativized(prefix)
      end
    end

    modify(modifier.new, resolve_status)
  end

  def can_equal(other)
    other.is_a?(self.class)
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality
    if other.is_a?(self.class)
      # optimization to avoid unwrapped() for two ConfigList
      can_equal(other) &&
          (value.equal?(other.value) || (value == other.value))
    else
      false
    end
  end

  def hash
    # note that "origin" is deliberately NOT part of equality
    value.hash
  end

  def render_value_to_sb(sb, indent_size, at_root, options)
    if @value.empty?
      sb << "[]"
    else
      sb << "["
      if options.formatted?
        sb << "\n"
      end
      @value.each do |v|
        if options.origin_comments?
          lines = v.origin.description.split("\n")
          lines.each do |l|
            Hocon::Impl::AbstractConfigValue.indent(sb, indent_size + 1, options)
            sb << "# "
            sb << l
            sb << "\n"
          end
        end
        if options.comments?
          v.origin.comments.each do |comment|
            sb << "# "
            sb << comment
            sb << "\n"
          end
        end
        Hocon::Impl::AbstractConfigValue.indent(sb, indent_size + 1, options)

        v.render_value_to_sb(sb, indent_size + 1, at_root, options)
        sb << ","
        if options.formatted?
          sb << "\n"
        end
      end

      # couldn't figure out a better way to chop characters off of the end of
      # the StringIO.  This relies on making sure that, prior to returning the
      # final string, we take a substring that ends at sb.pos.
      sb.pos = sb.pos - 1 # chop or newline
      if options.formatted?
        sb.pos = sb.pos - 1 # also chop comma
        sb << "\n"
        Hocon::Impl::AbstractConfigValue.indent(sb, indent_size, options)
      end
      sb << "]"
    end
  end

  def contains?(o)
    value.include?(o)
  end

  def include_all?(value_list)
    value_list.all? { |v| @value.include?(v)}
  end

  def contains_all?(c)
    include_all?(c)
  end

  def get(index)
    value[index]
  end

  def index_of(o)
    value.index(o)
  end

  def is_empty
    empty?
  end

  # Skipping upstream definition of "iterator", because that's not really a thing
  # in Ruby.

  def last_index_of(o)
    value.rindex(o)
  end

  # skipping upstream definitions of "wrapListIterator", "listIterator", and
  # "listIterator(int)", because those don't really apply in Ruby.

  def sub_list(from_index, to_index)
    value[from_index..to_index]
  end

  def to_array
    value
  end

  def we_are_immutable(method)
    Hocon::Impl::UnsupportedOperationError.new("ConfigList is immutable, you can't call List. '#{method}'")
  end

  def add(e)
    raise we_are_immutable("add")
  end

  def add_at(index, element)
    raise we_are_immutable("add_at")
  end

  def add_all(c)
    raise we_are_immutable("add_all")
  end

  def add_all_at(index, c)
    raise we_are_immutable("add_all_at")
  end

  def clear
    raise we_are_immutable("clear")
  end

  def remove(o)
    raise we_are_immutable("remove")
  end

  def remove_at(i)
    raise we_are_immutable("remove_at")
  end

  def delete(o)
    raise we_are_immutable("delete")
  end

  def remove_all(c)
    raise we_are_immutable("remove_all")
  end

  def retain_all(c)
    raise we_are_immutable("retain_all")
  end

  def set(index, element)
    raise we_are_immutable("set")
  end

  def []=(index, element)
    raise we_are_immutable("[]=")
  end

  def push(e)
    raise we_are_immutable("push")
  end

  def <<(e)
    raise we_are_immutable("<<")
  end

  def new_copy(origin)
    Hocon::Impl::SimpleConfigList.new(origin, @value)
  end

  def concatenate(other)
    combined_origin = Hocon::Impl::SimpleConfigOrigin.merge_two_origins(origin, other.origin)
    combined = value + other.value
    Hocon::Impl::SimpleConfigList.new(combined_origin, combined)
  end

  # Skipping upstream "writeReplace" until we see that we need it for something

  def with_origin(origin)
    super(origin)
  end

end
