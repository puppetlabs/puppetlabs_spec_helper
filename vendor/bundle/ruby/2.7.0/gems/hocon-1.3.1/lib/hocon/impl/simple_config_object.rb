# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/abstract_config_object'
require 'hocon/impl/resolve_status'
require 'hocon/impl/resolve_result'
require 'hocon/impl/path'
require 'hocon/config_error'
require 'set'
require 'forwardable'


class Hocon::Impl::SimpleConfigObject
  include Hocon::Impl::AbstractConfigObject
  extend Forwardable

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ResolveStatus = Hocon::Impl::ResolveStatus
  ResolveResult = Hocon::Impl::ResolveResult
  SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin
  Path = Hocon::Impl::Path


  def initialize(origin,
                 value,
                 status = Hocon::Impl::ResolveStatus.from_values(value.values),
                 ignores_fallbacks = false)
    super(origin)
    if value.nil?
      raise ConfigBugOrBrokenError, "creating config object with null map"
    end
    @value = value
    @resolved = (status == Hocon::Impl::ResolveStatus::RESOLVED)
    @ignores_fallbacks = ignores_fallbacks

    # Kind of an expensive debug check. Comment out?
    if status != Hocon::Impl::ResolveStatus.from_values(value.values)
      raise ConfigBugOrBrokenError, "Wrong resolved status on #{self}"
    end
  end

  attr_reader :value
  # To support accessing ConfigObjects like a hash
  def_delegators :@value, :[], :has_key?, :has_value?, :empty?, :size, :keys, :values, :each, :map


  def with_only_key(key)
    with_only_path(Path.new_key(key))
  end

  def without_key(key)
    without_path(Path.new_key(key))
  end

  # gets the object with only the path if the path
  # exists, otherwise null if it doesn't. this ensures
  # that if we have { a : { b : 42 } } and do
  # withOnlyPath("a.b.c") that we don't keep an empty
  # "a" object.
  def with_only_path_or_nil(path)
    key = path.first
    path_next = path.remainder
    v = value[key]

    if ! path_next.nil?
      if (!v.nil?) && (v.is_a?(Hocon::Impl::AbstractConfigObject))
        v = v.with_only_path_or_nil(path_next)
      else
        # if the path has more elements but we don't have an object,
        # then the rest of the path does not exist.
        v = nil
      end
    end

    if v.nil?
      nil
    else
      self.class.new(origin, {key => v}, v.resolve_status, @ignores_fallbacks)
    end
  end

  def with_only_path(path)
    o = with_only_path_or_nil(path)
    if o.nil?
      self.class.new(origin, {}, ResolveStatus::RESOLVED, @ignores_fallbacks)
    else
      o
    end
  end

  def without_path(path)
    key = path.first
    remainder = path.remainder
    v = @value[key]

    if (not v.nil?) && (not remainder.nil?) && v.is_a?(Hocon::Impl::AbstractConfigObject)
      v = v.without_path(remainder)
      updated = @value.clone
      updated[key] = v
      self.class.new(origin,
                     updated,
                     ResolveStatus.from_values(updated.values), @ignores_fallbacks)
    elsif (not remainder.nil?) || v.nil?
      return self
    else
      smaller = Hash.new
      @value.each do |old_key, old_value|
        unless old_key == key
          smaller[old_key] = old_value
        end
      end
      self.class.new(origin,
                     smaller,
                     ResolveStatus.from_values(smaller.values), @ignores_fallbacks)
    end
  end

  def with_value(path, v)
    key = path.first
    remainder = path.remainder

    if remainder.nil?
      with_key_value(key, v)
    else
      child = @value[key]
      if (not child.nil?) && child.is_a?(Hocon::Impl::AbstractConfigObject)
        return with_key_value(key, child.with_value(remainder, v))
      else
        subtree = v.at_path_with_origin(
            SimpleConfigOrigin.new_simple("with_value(#{remainder.render})"), remainder)
        with_key_value(key, subtree.root)
      end
    end
  end

  def with_key_value(key, v)
    if v.nil?
      raise ConfigBugOrBrokenError.new("Trying to store null ConfigValue in a ConfigObject")
    end

    new_map = Hash.new
    if @value.empty?
      new_map[key] = v
    else
      new_map = @value.clone
      new_map[key] = v
    end
    self.class.new(origin, new_map, ResolveStatus.from_values(new_map.values), @ignores_fallbacks)
  end

  def attempt_peek_with_partial_resolve(key)
    @value[key]
  end

  def new_copy_with_status(new_status, new_origin, new_ignores_fallbacks = nil)
    self.class.new(new_origin, @value, new_status, new_ignores_fallbacks)
  end

  def with_fallbacks_ignored()
    if @ignores_fallbacks
      self
    else
      new_copy_with_status(resolve_status, origin, true)
    end
  end

  def resolve_status
    ResolveStatus.from_boolean(@resolved)
  end

  def replace_child(child, replacement)
    new_children = @value.clone
    new_children.each do |old, old_value|
      if old_value.equal?(child)
        if replacement != nil
          new_children[old] = replacement
        else
          new_children.delete(old)
        end

        return self.class.new(origin, new_children, ResolveStatus.from_values(new_children.values),
                       @ignores_fallbacks)
      end
    end
    raise ConfigBugOrBrokenError, "SimpleConfigObject.replaceChild did not find #{child} in #{self}"
  end

  def has_descendant?(descendant)
    value.values.each do |child|
      if child.equal?(descendant)
        return true
      end
    end
    # now do the expensive search
    value.values.each do |child|
      if child.is_a?(Hocon::Impl::Container) && child.has_descendant?(descendant)
        return true
      end
    end

    false
  end

  def ignores_fallbacks?
    @ignores_fallbacks
  end

  def unwrapped
    m = {}
    @value.each do |k,v|
      m[k] = v.unwrapped
    end
    m
  end

  def merged_with_object(abstract_fallback)
    require_not_ignoring_fallbacks

    unless abstract_fallback.is_a?(Hocon::Impl::SimpleConfigObject)
      raise ConfigBugOrBrokenError, "should not be reached (merging non-SimpleConfigObject)"
    end

    fallback = abstract_fallback
    changed = false
    all_resolved = true
    merged = {}
    all_keys = key_set.union(fallback.key_set)
    all_keys.each do |key|
      first = @value[key]
      second = fallback.value[key]
      kept =
          if first.nil?
            second
          elsif second.nil?
            first
          else
            first.with_fallback(second)
          end
      merged[key] = kept

      if first != kept
        changed = true
      end

      if kept.resolve_status == Hocon::Impl::ResolveStatus::UNRESOLVED
        all_resolved = false
      end
    end

    new_resolve_status = Hocon::Impl::ResolveStatus.from_boolean(all_resolved)
    new_ignores_fallbacks = fallback.ignores_fallbacks?

    if changed
      Hocon::Impl::SimpleConfigObject.new(Hocon::Impl::AbstractConfigObject.merge_origins([self, fallback]),
                                          merged, new_resolve_status,
                                          new_ignores_fallbacks)
    elsif (new_resolve_status != resolve_status) || (new_ignores_fallbacks != ignores_fallbacks?)
      new_copy_with_status(new_resolve_status, origin, new_ignores_fallbacks)
    else
      self
    end
  end

  def modify(modifier)
    begin
      modify_may_throw(modifier)
    rescue Hocon::ConfigError => e
      raise e
    end
  end

  def modify_may_throw(modifier)
    changes = nil
    keys.each do |k|
      v = value[k]
      # "modified" may be null, which means remove the child;
      # to do that we put null in the "changes" map.
      modified = modifier.modify_child_may_throw(k, v)
      if ! modified.equal?(v)
        if changes.nil?
          changes = {}
        end
        changes[k] = modified
      end
    end
    if changes.nil?
      self
    else
      modified = {}
      saw_unresolved = false
      keys.each do |k|
        if changes.has_key?(k)
          new_value = changes[k]
          if ! new_value.nil?
            modified[k] = new_value
            if new_value.resolve_status == ResolveStatus::UNRESOLVED
              saw_unresolved = true
            end
          else
            # remove this child; don't put it in the new map
          end
        else
          new_value = value[k]
          modified[k] = new_value
          if new_value.resolve_status == ResolveStatus::UNRESOLVED
            saw_unresolved = true
          end
        end
      end
      self.class.new(origin, modified,
                     saw_unresolved ? ResolveStatus::UNRESOLVED : ResolveStatus::RESOLVED,
                     @ignores_fallbacks)
    end
  end


  class ResolveModifier

    attr_accessor :context
    attr_reader :source

    def initialize(context, source)
      @context = context
      @source = source
      @original_restrict = context.restrict_to_child
    end

    def modify_child_may_throw(key, v)
       if @context.is_restricted_to_child
        if key == @context.restrict_to_child.first
          remainder = @context.restrict_to_child.remainder
          if remainder != nil
            result = @context.restrict(remainder).resolve(v, @source)
            @context = result.context.unrestricted.restrict(@original_restrict)
            return result.value
          else
            # we don't want to resolve the leaf child
            return v
          end
        else
          # not in the restrictToChild path
          return v
        end
      else
        # no restrictToChild, resolve everything
        result = @context.unrestricted.resolve(v, @source)
        @context = result.context.unrestricted.restrict(@original_restrict)
        result.value
      end
    end
  end

  def resolve_substitutions(context, source)
    if resolve_status == ResolveStatus::RESOLVED
      return ResolveResult.make(context, self)
    end

    source_with_parent = source.push_parent(self)

    begin
      modifier = ResolveModifier.new(context, source_with_parent)

      value = modify_may_throw(modifier)
      ResolveResult.make(modifier.context, value)

    rescue NotPossibleToResolve => e
      raise e
    rescue Hocon::ConfigError => e
      raise e
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

    modify(modifier.new)
  end

  class RenderComparator
    def self.all_digits?(s)
      s =~ /^\d+$/
    end

    # This is supposed to sort numbers before strings,
    # and sort the numbers numerically. The point is
    # to make objects which are really list-like
    # (numeric indices) appear in order.
    def self.sort(arr)
      arr.sort do |a, b|
        a_digits = all_digits?(a)
        b_digits = all_digits?(b)
        if a_digits && b_digits
          Integer(a) <=> Integer(b)
        elsif a_digits
          -1
        elsif b_digits
          1
        else
          a <=> b
        end
      end
    end
  end

  def render_value_to_sb(sb, indent, at_root, options)
    if empty?
      sb << "{}"
    else
      outer_braces = options.json? || !at_root

      if outer_braces
        inner_indent = indent + 1
        sb << "{"

        if options.formatted?
          sb << "\n"
        end
      else
        inner_indent = indent
      end

      separator_count = 0
      sorted_keys = RenderComparator.sort(keys)
      sorted_keys.each do |k|
        v = @value[k]

        if options.origin_comments?
          lines = v.origin.description.split("\n")
          lines.each { |l|
            Hocon::Impl::AbstractConfigValue.indent(sb, indent + 1, options)
            sb << '#'
            unless l.empty?
              sb << ' '
            end
            sb << l
            sb << "\n"
          }
        end
        if options.comments?
          v.origin.comments.each do |comment|
            Hocon::Impl::AbstractConfigValue.indent(sb, inner_indent, options)
            sb << "#"
            if !comment.start_with?(" ")
              sb << " "
            end
            sb << comment
            sb << "\n"
          end
        end
        Hocon::Impl::AbstractConfigValue.indent(sb, inner_indent, options)
        v.render_to_sb(sb, inner_indent, false, k.to_s, options)

        if options.formatted?
          if options.json?
            sb << ","
            separator_count = 2
          else
            separator_count = 1
          end
          sb << "\n"
        else
          sb << ","
          separator_count = 1
        end
      end
      # chop last commas/newlines
      # couldn't figure out a better way to chop characters off of the end of
      # the StringIO.  This relies on making sure that, prior to returning the
      # final string, we take a substring that ends at sb.pos.
      sb.pos = sb.pos - separator_count

      if outer_braces
        if options.formatted?
          sb << "\n" # put a newline back
          if outer_braces
            Hocon::Impl::AbstractConfigValue.indent(sb, indent, options)
          end
        end
        sb << "}"
      end
    end
    if at_root && options.formatted?
      sb << "\n"
    end
  end

  def self.map_equals(a, b)
    if a.equal?(b)
      return true
    end

    # Hashes aren't ordered in ruby, so sort first
    if not a.keys.sort == b.keys.sort
      return false
    end

    a.keys.each do |key|
      if a[key] != b[key]
        return false
      end
    end

    true
  end

  def get(key)
    @value[key]
  end

  def self.map_hash(m)
    # the keys have to be sorted, otherwise we could be equal
    # to another map but have a different hashcode.
    keys = m.keys.sort

    value_hash = 0

    keys.each do |key|
      value_hash += m[key].hash
    end

    41 * (41 + keys.hash) + value_hash
  end

  def can_equal(other)
    other.is_a? Hocon::ConfigObject
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality.
    # neither are other "extras" like ignoresFallbacks or resolve status.
    if other.is_a? Hocon::ConfigObject
      # optimization to avoid unwrapped() for two ConfigObject,
      # which is what AbstractConfigValue does.
      can_equal(other) && self.class.map_equals(self, other)
    else
      false
    end
  end

  def hash
    self.class.map_hash(@value)
  end

  def contains_key?(key)
    @value.has_key?(key)
  end

  def key_set
    Set.new(@value.keys)
  end

  def contains_value?(v)
    @value.has_value?(v)
  end

  def self.empty(origin = nil)
    if origin.nil?
      empty(Hocon::Impl::SimpleConfigOrigin.new_simple("empty config"))
    else
      self.new(origin, {})
    end
  end

  def self.empty_missing(base_origin)
    self.new(
        Hocon::Impl::SimpleConfigOrigin.new_simple("#{base_origin.description} (not found)"),
        {})
  end
end

