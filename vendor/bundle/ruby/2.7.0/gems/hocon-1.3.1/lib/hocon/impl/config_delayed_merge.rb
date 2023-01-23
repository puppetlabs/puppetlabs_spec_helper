require 'hocon/impl'
require 'hocon/impl/replaceable_merge_stack'
require 'hocon/impl/config_delayed_merge_object'
require 'hocon/impl/config_impl'
require 'hocon/impl/resolve_result'
require 'hocon/impl/abstract_config_value'

#
# The issue here is that we want to first merge our stack of config files, and
# then we want to evaluate substitutions. But if two substitutions both expand
# to an object, we might need to merge those two objects. Thus, we can't ever
# "override" a substitution when we do a merge; instead we have to save the
# stack of values that should be merged, and resolve the merge when we evaluate
# substitutions.
#
class Hocon::Impl::ConfigDelayedMerge
  include Hocon::Impl::Unmergeable
  include Hocon::Impl::ReplaceableMergeStack
  include Hocon::Impl::AbstractConfigValue

  ConfigImpl = Hocon::Impl::ConfigImpl
  ResolveResult = Hocon::Impl::ResolveResult

  def initialize(origin, stack)
    super(origin)
    @stack = stack

    if stack.empty?
      raise Hocon::ConfigError::ConfigBugOrBrokenError.new("creating empty delayed merge value", nil)
    end

    stack.each do |v|
      if v.is_a?(Hocon::Impl::ConfigDelayedMerge) || v.is_a?(Hocon::Impl::ConfigDelayedMergeObject)
        error_message = "placed nested DelayedMerge in a ConfigDelayedMerge, should have consolidated stack"
        raise Hocon::ConfigError::ConfigBugOrBrokenError.new(error_message, nil)
      end
    end
  end

  attr_reader :stack


  def value_type
    error_message = "called value_type() on value with unresolved substitutions, need to Config#resolve() first, see API docs"
    raise Hocon::ConfigError::ConfigNotResolvedError.new(error_message, nil)
  end

  def unwrapped
    error_message = "called unwrapped() on value with unresolved substitutions, need to Config#resolve() first, see API docs"
    raise Hocon::ConfigError::ConfigNotResolvedError.new(error_message, nil)
  end

  def resolve_substitutions(context, source)
    self.class.resolve_substitutions(self, stack, context, source)
  end

  def self.resolve_substitutions(replaceable, stack, context, source)
    if ConfigImpl.trace_substitution_enabled
      ConfigImpl.trace("delayed merge stack has #{stack.size} items:", context.depth)
      count = 0
      stack.each do |v|
        ConfigImpl.trace("#{count}: #{v}", context.depth)
        count += 1
      end
    end

    # to resolve substitutions, we need to recursively resolve
    # the stack of stuff to merge, and merge the stack so
    # we won't be a delayed merge anymore. If restrictToChildOrNull
    # is non-null, or resolve options allow partial resolves,
    # we may remain a delayed merge though.

    new_context = context
    count = 0
    merged = nil
    stack.each do |stack_end|
      # the end value may or may not be resolved already

      if stack_end.is_a?(Hocon::Impl::ReplaceableMergeStack)
        raise ConfigBugOrBrokenError, "A delayed merge should not contain another one: #{replaceable}"
      elsif stack_end.is_a?(Hocon::Impl::Unmergeable)
        # the remainder could be any kind of value, including another
        # ConfigDelayedMerge
        remainder = replaceable.make_replacement(context, count + 1)

        if ConfigImpl.trace_substitution_enabled
          ConfigImpl.trace("remainder portion: #{remainder}", new_context.depth)
        end

        # If, while resolving 'end' we come back to the same
        # merge stack, we only want to look _below_ 'end'
        # in the stack. So we arrange to replace the
        # ConfigDelayedMerge with a value that is only
        # the remainder of the stack below this one.

        if ConfigImpl.trace_substitution_enabled
          ConfigImpl.trace("building sourceForEnd", new_context.depth)
        end

        # we resetParents() here because we'll be resolving "end"
        # against a root which does NOT contain "end"
        source_for_end = source.replace_within_current_parent(replaceable, remainder)

        if ConfigImpl.trace_substitution_enabled
          ConfigImpl.trace("  sourceForEnd before reset parents but after replace: #{source_for_end}", new_context.depth)
        end

        source_for_end = source_for_end.reset_parents
      else
        if ConfigImpl.trace_substitution_enabled
          ConfigImpl.trace("will resolve end against the original source with parent pushed",
                           new_context.depth)
        end

        source_for_end = source.push_parent(replaceable)
      end

      if ConfigImpl.trace_substitution_enabled
        ConfigImpl.trace("sourceForEnd      =#{source_for_end}", new_context.depth)
      end

      if ConfigImpl.trace_substitution_enabled
        ConfigImpl.trace("Resolving highest-priority item in delayed merge #{stack_end}" +
                          " against #{source_for_end} endWasRemoved=#{(source != source_for_end)}")
      end

      result = new_context.resolve(stack_end, source_for_end)
      resolved_end = result.value
      new_context = result.context

      if ! resolved_end.nil?
        if merged.nil?
          merged = resolved_end
        else
          if ConfigImpl.trace_substitution_enabled
            ConfigImpl.trace("merging #{merged} with fallback #{resolved_end}",
                             new_context.depth + 1)
          end
          merged = merged.with_fallback(resolved_end)
        end
      end

      count += 1

      if ConfigImpl.trace_substitution_enabled
        ConfigImpl.trace("stack merged, yielding: #{merged}",
                         new_context.depth)
      end
    end

    ResolveResult.make(new_context, merged)
  end

  def make_replacement(context, skipping)
    self.class.make_replacement(context, @stack, skipping)
  end

  # static method also used by ConfigDelayedMergeObject; end may be null
  def self.make_replacement(context, stack, skipping)
    sub_stack = stack.slice(skipping..stack.size)

    if sub_stack.empty?
      if ConfigImpl.trace_substitution_enabled
        ConfigImpl.trace("Nothing else in the merge stack, replacing with null", context.depth)
        return nil
      end
    else
      # generate a new merge stack from only the remaining items
      merged = nil
      sub_stack.each do |v|
        if merged.nil?
          merged = v
        else
          merged = merged.with_fallback(v)
        end
      end
      merged
    end
  end

  def resolve_status
    Hocon::Impl::ResolveStatus::UNRESOLVED
  end

  def replace_child(child, replacement)
    new_stack = replace_child_in_list(stack, child, replacement)
    if new_stack.nil?
      nil
    else
      self.class.new(origin, new_stack)
    end
  end

  def has_descendant?(descendant)
    Hocon::Impl::AbstractConfigValue.has_descendant_in_list?(stack, descendant)
  end

  def relativized(prefix)
    new_stack = stack.map { |o| o.relativized(prefix) }
    self.class.new(origin, new_stack)
  end

  # static utility shared with ConfigDelayedMergeObject
  def self.stack_ignores_fallbacks?(stack)
    last = stack[-1]
    last.ignores_fallbacks?
  end

  def ignores_fallbacks?
    self.class.stack_ignores_fallbacks?(stack)
  end

  def new_copy(new_origin)
    self.class.new(new_origin, stack)
  end

  def merged_with_the_unmergeable(fallback)
    merged_stack_with_the_unmergeable(stack, fallback)
  end

  def merged_with_object(fallback)
    merged_stack_with_object(stack, fallback)
  end

  def merged_with_non_object(fallback)
    merged_stack_with_non_object(stack, fallback)
  end

  def unmerged_values
    stack
  end

  def can_equal(other)
    other.is_a? Hocon::Impl::ConfigDelayedMerge
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality
    if other.is_a? Hocon::Impl::ConfigDelayedMerge
      can_equal(other) && (@stack == other.stack || @stack.equal?(other.stack))
    else
      false
    end
  end

  def hash
    # note that "origin" is deliberately NOT part of equality
    @stack.hash
  end

  def render_to_sb(sb, indent, at_root, at_key, options)
    self.class.render_value_to_sb_from_stack(stack, sb, indent, at_root, at_key, options)
  end

  # static method also used by ConfigDelayedMergeObject.
  def self.render_value_to_sb_from_stack(stack, sb, indent, at_root, at_key, options)
    comment_merge = options.comments

    if comment_merge
      sb << "# unresolved merge of #{stack.size} values follows (\n"
      if at_key.nil?
        self.indent(sb, indent, options)
        sb << "# this unresolved merge will not be parseable because it's at the root of the object\n"
        self.indent(sb, indent, options)
        sb << "# the HOCON format has no way to list multiple root objects in a single file\n"
      end
    end

    reversed = stack.reverse

    i = 0

    reversed.each do |v|
      if comment_merge
        self.indent(sb, indent, options)
        if !at_key.nil?
          rendered_key = Hocon::Impl::ConfigImplUtil.render_json_string(at_key)
          sb << "#     unmerged value #{i} for key #{rendered_key}"
        else
          sb << "#     unmerged value #{i} from "
        end
        i += 1

        sb << v.origin.description
        sb << "\n"

        v.origin.comments.each do |comment|
          self.indent(sb, indent, options)
          sb << "# "
          sb << comment
          sb << "\n"
        end
      end
      Hocon::Impl::AbstractConfigValue.indent(sb, indent, options)

      if !at_key.nil?
        sb << Hocon::Impl::ConfigImplUtil.render_json_string(at_key)
        if options.formatted
          sb << ": "
        else
          sb << ":"
        end
      end

      v.render_value_to_sb(sb, indent, at_root, options)
      sb << ","

      if options.formatted
        sb.append "\n"
      end
    end

    # chop comma or newline
    # couldn't figure out a better way to chop characters off of the end of
    # the StringIO.  This relies on making sure that, prior to returning the
    # final string, we take a substring that ends at sb.pos.
    sb.pos = sb.pos - 1
    if options.formatted
      sb.pos = sb.pos - 1
      sb << "\n"
    end

    if comment_merge
      self.indent(sb, indent, options)
      sb << "# ) end of unresolved merge\n"
    end
  end

end
