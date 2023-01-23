# encoding: utf-8

require 'hocon/impl'
require 'stringio'
require 'hocon/config_render_options'
require 'hocon/config_object'
require 'hocon/impl/resolve_status'
require 'hocon/impl/resolve_result'
require 'hocon/impl/unmergeable'
require 'hocon/impl/config_impl_util'
require 'hocon/config_error'
require 'hocon/config_value'

##
## Trying very hard to avoid a parent reference in config values; when you have
## a tree like this, the availability of parent() tends to result in a lot of
## improperly-factored and non-modular code. Please don't add parent().
##
module Hocon::Impl::AbstractConfigValue
  include Hocon::ConfigValue

  ConfigImplUtil = Hocon::Impl::ConfigImplUtil
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ResolveStatus = Hocon::Impl::ResolveStatus

  def initialize(origin)
    @origin = origin
  end

  attr_reader :origin

  # This exception means that a value is inherently not resolveable, at the
  # moment the only known cause is a cycle of substitutions. This is a
  # checked exception since it's internal to the library and we want to be
  # sure we handle it before passing it out to public API. This is only
  # supposed to be thrown by the target of a cyclic reference and it's
  # supposed to be caught by the ConfigReference looking up that reference,
  # so it should be impossible for an outermost resolve() to throw this.
  #
  # Contrast with ConfigException.NotResolved which just means nobody called
  # resolve().
  class NotPossibleToResolve < Exception
    def initialize(context)
      super("was not possible to resolve")
      @trace_string = context.trace_string
    end

    attr_reader :trace_string
  end

  # Called only by ResolveContext.resolve
  #
  # @param context
  #            state of the current resolve
  # @param source
  #            where to look up values
  # @return a new value if there were changes, or this if no changes
  def resolve_substitutions(context, source)
    Hocon::Impl::ResolveResult.make(context, self)
  end

  def resolve_status
    Hocon::Impl::ResolveStatus::RESOLVED
  end

  def self.replace_child_in_list(list, child, replacement)
    i = 0
    while (i < list.size) && (! list[i].equal?(child))
      i += 1
    end
    if (i == list.size)
      raise ConfigBugOrBrokenError, "tried to replace #{child} which is not in #{list}"
    end

    new_stack = list.clone
    if ! replacement.nil?
      new_stack[i] = replacement
    else
      new_stack.delete(i)
    end

    if new_stack.empty?
      nil
    else
      new_stack
    end
  end

  def self.has_descendant_in_list?(list, descendant)
    list.each do |v|
      if v.equal?(descendant)
        return true
      end
    end
    # now the expensive traversal
    list.each do |v|
      if v.is_a?(Hocon::Impl::Container) && v.has_descendant?(descendant)
        return true
      end
    end
    false
  end

  # This is used when including one file in another; the included file is
  # relativized to the path it's included into in the parent file. The point
  # is that if you include a file at foo.bar in the parent, and the included
  # file as a substitution ${a.b.c}, the included substitution now needs to
  # be ${foo.bar.a.b.c} because we resolve substitutions globally only after
  # parsing everything.
  #
  # @param prefix
  # @return value relativized to the given path or the same value if nothing
  #         to do
  def relativized(prefix)
    self
  end

  module NoExceptionsModifier
    def modify_child_may_throw(key_or_nil, v)
      begin
        modify_child(key_or_nil, v)
      rescue Hocon::ConfigError => e
        raise e
      end
    end
  end

  def to_fallback_value
    self
  end

  def new_copy(origin)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigValue should provide their own implementation of `new_copy` (#{self.class})"
  end

  # this is virtualized rather than a field because only some subclasses
  # really need to store the boolean, and they may be able to pack it
  # with another boolean to save space.
  def ignores_fallbacks?
    # if we are not resolved, then somewhere in this value there's
    # a substitution that may need to look at the fallbacks.
    resolve_status == Hocon::Impl::ResolveStatus::RESOLVED
  end

  def with_fallbacks_ignored
    if ignores_fallbacks?
      self
    else
      raise ConfigBugOrBrokenError, "value class doesn't implement forced fallback-ignoring #{self}"
    end
  end

  # the withFallback() implementation is supposed to avoid calling
  # mergedWith* if we're ignoring fallbacks.
  def require_not_ignoring_fallbacks
    if ignores_fallbacks?
      raise ConfigBugOrBrokenError, "method should not have been called with ignoresFallbacks=true #{self.class.name}"
    end
  end

  def construct_delayed_merge(origin, stack)
    # TODO: this might not work because ConfigDelayedMerge inherits
    # from this class, so we can't `require` it from this file
    require 'hocon/impl/config_delayed_merge'
    Hocon::Impl::ConfigDelayedMerge.new(origin, stack)
  end

  def merged_stack_with_the_unmergeable(stack, fallback)
    require_not_ignoring_fallbacks

    # if we turn out to be an object, and the fallback also does,
    # then a merge may be required; delay until we resolve.
    new_stack = stack.clone
    new_stack.concat(fallback.unmerged_values)
    # TODO: this might not work because AbstractConfigObject inherits
    # from this class, so we can't `require` it from this file
    construct_delayed_merge(Hocon::Impl::AbstractConfigObject.merge_origins(new_stack), new_stack)
  end

  def delay_merge(stack, fallback)
    # if we turn out to be an object, and the fallback also does,
    # then a merge may be required.
    # if we contain a substitution, resolving it may need to look
    # back to the fallback
    new_stack = stack.clone
    new_stack << fallback
    # TODO: this might not work because AbstractConfigObject inherits
    # from this class, so we can't `require` it from this file
    construct_delayed_merge(Hocon::Impl::AbstractConfigObject.merge_origins(new_stack), new_stack)
  end

  def merged_stack_with_object(stack, fallback)
    require_not_ignoring_fallbacks

    # TODO: this might not work because AbstractConfigObject inherits
    # from this class, so we can't `require` it from this file
    if self.is_a?(Hocon::Impl::AbstractConfigObject)
      raise ConfigBugOrBrokenError, "Objects must reimplement merged_with_object"
    end

    merged_stack_with_non_object(stack, fallback)
  end

  def merged_stack_with_non_object(stack, fallback)
    require_not_ignoring_fallbacks

    if resolve_status == ResolveStatus::RESOLVED
      # falling back to a non-object doesn't merge anything, and also
      # prohibits merging any objects that we fall back to later.
      # so we have to switch to ignoresFallbacks mode.
      with_fallbacks_ignored
    else
      # if unresolved we may have to look back to fallbacks as part of
      # the resolution process, so always delay
      delay_merge(stack, fallback)
    end
  end

  def merged_with_the_unmergeable(fallback)
    require_not_ignoring_fallbacks
    merged_stack_with_the_unmergeable([self], fallback)
  end

  def merged_with_object(fallback)
    require_not_ignoring_fallbacks
    merged_stack_with_object([self], fallback)
  end

  def merged_with_non_object(fallback)
    require_not_ignoring_fallbacks
    merged_stack_with_non_object([self], fallback)
  end

  def with_origin(origin)
    if @origin.equal?(origin)
      self
    else
      new_copy(origin)
    end
  end

  def with_fallback(mergeable)
    if ignores_fallbacks?
      self
    else
      other = mergeable.to_fallback_value
      if other.is_a?(Hocon::Impl::Unmergeable)
        merged_with_the_unmergeable(other)
        # TODO: this probably isn't going to work because AbstractConfigObject inherits
        # from this class, so we can't `require` it from this file
      elsif other.is_a?(Hocon::Impl::AbstractConfigObject)
        merged_with_object(other)
      else
        merged_with_non_object(other)
      end
    end
  end

  def can_equal(other)
    other.is_a?(Hocon::Impl::AbstractConfigValue)
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality
    if other.is_a?(Hocon::Impl::AbstractConfigValue)
      can_equal(other) &&
          value_type == other.value_type &&
          ConfigImplUtil.equals_handling_nil?(unwrapped, other.unwrapped)
    else
      false
    end
  end

  def hash
    # note that "origin" is deliberately NOT part of equality
    unwrapped_value = unwrapped
    if unwrapped_value.nil?
      0
    else
      unwrapped_value.hash
    end
  end

  def to_s
    sb = StringIO.new
    render_to_sb(sb, 0, true, nil, Hocon::ConfigRenderOptions.concise)
    "#{self.class.name.split('::').last}(#{sb.string})"
  end

  def inspect
    to_s
  end

  def self.indent(sb, indent_size, options)
    if options.formatted?
      remaining = indent_size
      while remaining > 0
        sb << "    "
        remaining -= 1
      end
    end
  end

  def render_to_sb(sb, indent, at_root, at_key, options)
    if !at_key.nil?
      rendered_key =
          if options.json?
            ConfigImplUtil.render_json_string(at_key)
          else
            ConfigImplUtil.render_string_unquoted_if_possible(at_key)
          end

      sb << rendered_key

      if options.json?
        if options.formatted?
          sb << ": "
        else
          sb << ":"
        end
      else
        case options.key_value_separator
          when :colon
            sb << ": "
          else
            sb << "="
        end      end
    end
    render_value_to_sb(sb, indent, at_root, options)
  end

  # to be overridden by subclasses
  def render_value_to_sb(sb, indent, at_root, options)
    u = unwrapped
    sb << u.to_s
  end

  def render(options = Hocon::ConfigRenderOptions.defaults)
    sb = StringIO.new
    render_to_sb(sb, 0, true, nil, options)
    # We take a substring that ends at sb.pos, because we've been decrementing
    # sb.pos at various points in the code as a means to remove characters from
    # the end of the StringIO
    sb.string[0, sb.pos]
  end

  # toString() is a debugging-oriented string but this is defined
  # to create a string that would parse back to the value in JSON.
  # It only works for primitive values (that would be a single
  # which are auto-converted to strings when concatenating with
  # other strings or by the DefaultTransformer.
  def transform_to_string
    nil
  end

  def at_key(key)
    at_key_with_origin(Hocon::Impl::SimpleConfigOrigin.new_simple("at_key(#{key})"), key)
  end

  # Renamed this to be consistent with the other at_key* overloaded methods
  def at_key_with_origin(origin, key)
    m = {key=>self}
    Hocon::Impl::SimpleConfigObject.new(origin, m).to_config
  end

  # In java this is an overloaded version of atPath
  def at_path_with_origin(origin, path)
    parent = path.parent
    result = at_key_with_origin(origin, path.last)
    while not parent.nil? do
      key = parent.last
      result = result.at_key_with_origin(origin, key)
      parent = parent.parent
    end
    result
  end

  def at_path(path_expression)
    origin = Hocon::Impl::SimpleConfigOrigin.new_simple("at_path(#{path_expression})")
    at_path_with_origin(origin, Hocon::Impl::Path.new_path(path_expression))
  end

end
