# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_value'
require 'hocon/impl/abstract_config_object'
require 'hocon/impl/simple_config_list'
require 'hocon/config_object'
require 'hocon/impl/unmergeable'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/config_string'
require 'hocon/impl/container'

class Hocon::Impl::ConfigConcatenation
  include Hocon::Impl::Unmergeable
  include Hocon::Impl::Container
  include Hocon::Impl::AbstractConfigValue

  SimpleConfigList = Hocon::Impl::SimpleConfigList
  ConfigObject = Hocon::ConfigObject
  ConfigString = Hocon::Impl::ConfigString
  ResolveStatus = Hocon::Impl::ResolveStatus
  Unmergeable = Hocon::Impl::Unmergeable
  SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError
  ConfigWrongTypeError = Hocon::ConfigError::ConfigWrongTypeError

  attr_reader :pieces

  def initialize(origin, pieces)
    super(origin)
    @pieces = pieces

    if pieces.size < 2
      raise ConfigBugOrBrokenError, "Created concatenation with less than 2 items: #{self}"
    end

    had_unmergeable = false
    pieces.each do |p|
      if p.is_a?(Hocon::Impl::ConfigConcatenation)
        raise ConfigBugOrBrokenError, "ConfigConcatenation should never be nested: #{self}"
      end
      if p.is_a?(Unmergeable)
        had_unmergeable = true
      end
    end

    unless had_unmergeable
      raise ConfigBugOrBrokenError, "Created concatenation without an unmergeable in it: #{self}"
    end
  end

  def value_type
    raise not_resolved
  end

  def unwrapped
    raise not_resolved
  end

  def new_copy(new_origin)
    self.class.new(new_origin, @pieces)
  end

  def ignores_fallbacks?
    # we can never ignore fallbacks because if a child ConfigReference
    # is self-referential we have to look lower in the merge stack
    # for its value.
    false
  end

  def unmerged_values
    [self]
  end

  #
  # Add left and right, or their merger, to builder
  #
  def self.join(builder, orig_right)
    left = builder[builder.size - 1]
    right = orig_right

    # check for an object which can be converted to a list
    # (this will be an object with numeric keys, like foo.0, foo.1)
    if (left.is_a?(ConfigObject)) && (right.is_a?(SimpleConfigList))
      left = Hocon::Impl::DefaultTransformer.transform(left, Hocon::ConfigValueType::LIST)
    elsif (left.is_a?(SimpleConfigList)) && (right.is_a?(ConfigObject))
      right = Hocon::Impl::DefaultTransformer.transform(right, Hocon::ConfigValueType::LIST)
    end

    # Since this depends on the type of two instances, I couldn't think
    # of much alternative to an instanceof chain. Visitors are sometimes
    # used for multiple dispatch but seems like overkill.
    joined = nil
    if (left.is_a?(ConfigObject)) && (right.is_a?(ConfigObject))
      joined = right.with_fallback(left)
    elsif (left.is_a?(SimpleConfigList)) && (right.is_a?(SimpleConfigList))
      joined = left.concatenate(right)
    elsif (left.is_a?(SimpleConfigList) || left.is_a?(ConfigObject)) &&
           is_ignored_whitespace(right)
      joined = left
      # it should be impossible that left is whitespace and right is a list or object
    elsif (left.is_a?(Hocon::Impl::ConfigConcatenation)) ||
        (right.is_a?(Hocon::Impl::ConfigConcatenation))
      raise ConfigBugOrBrokenError, "unflattened ConfigConcatenation"
    elsif (left.is_a?(Unmergeable)) || (right.is_a?(Unmergeable))
      # leave joined=null, cannot join
    else
      # handle primitive type or primitive type mixed with object or list
      s1 = left.transform_to_string
      s2 = right.transform_to_string
      if s1.nil? || s2.nil?
        raise ConfigWrongTypeError.new(left.origin,
                "Cannot concatenate object or list with a non-object-or-list, #{left} " +
                    "and #{right} are not compatible", nil)
      else
        joined_origin = SimpleConfigOrigin.merge_origins([left.origin, right.origin])
        joined = Hocon::Impl::ConfigString::Quoted.new(joined_origin, s1 + s2)
      end
    end

    if joined.nil?
      builder.push(right)
    else
      builder.pop
      builder.push(joined)
    end
  end

  def self.consolidate(pieces)
    if pieces.length < 2
      pieces
    else
      flattened = []
      pieces.each do |v|
        if v.is_a?(Hocon::Impl::ConfigConcatenation)
          flattened.concat(v.pieces)
        else
          flattened.push(v)
        end
      end

      consolidated = []
      flattened.each do |v|
        if consolidated.empty?
          consolidated.push(v)
        else
          join(consolidated, v)
        end
      end

      consolidated
    end
  end

  def self.concatenate(pieces)
    consolidated = consolidate(pieces)
    if consolidated.empty?
      nil
    elsif consolidated.length == 1
      consolidated[0]
    else
      merged_origin = SimpleConfigOrigin.merge_value_origins(consolidated)
      Hocon::Impl::ConfigConcatenation.new(merged_origin, consolidated)
    end
  end

  def resolve_substitutions(context, source)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      indent = context.depth + 2
      Hocon::Impl::ConfigImpl.trace("concatenation has #{@pieces.size} pieces",
                                    indent - 1)
      count = 0
      @pieces.each { |v|
        Hocon::Impl::ConfigImpl.trace("#{count}: #{v}", count)
        count += 1
      }
    end

    # Right now there's no reason to pushParent here because the
    # content of ConfigConcatenation should not need to replaceChild,
    # but if it did we'd have to do this.
    source_with_parent = source
    new_context = context

    resolved = []
    @pieces.each { |p|
      # to concat into a string we have to do a full resolve,
      # so unrestrict the context, then put restriction back afterward
      restriction = new_context.restrict_to_child
      result = new_context.unrestricted
                   .resolve(p, source_with_parent)
      r = result.value
      new_context = result.context.restrict(restriction)
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace("resolved concat piece to #{r}",
                                      context.depth)
      end

      if r
        resolved << r
      end
      # otherwise, it was optional ... omit
    }

    # now need to concat everything
    joined = self.class.consolidate(resolved)
    # if unresolved is allowed we can just become another
    # ConfigConcatenation
    if joined.size > 1 and context.options.allow_unresolved
      Hocon::Impl::ResolveResult.make(new_context, Hocon::Impl::ConfigConcatenation.new(origin, joined))
    elsif joined.empty?
      # we had just a list of optional references using ${?}
      Hocon::Impl::ResolveResult.make(new_context, nil)
    elsif joined.size == 1
      Hocon::Impl::ResolveResult.make(new_context, joined[0])
    else
      raise ConfigBugOrBrokenError.new(
                "Bug in the library; resolved list was joined to too many values: #{joined}")
    end
  end

  def resolve_status
    ResolveStatus::UNRESOLVED
  end

  def replace_child(child, replacement)
    new_pieces = replace_child_in_list(@pieces, child, replacement)
    if new_pieces == nil
      nil
    else
      self.class.new(origin, new_pieces)
    end
  end

  def has_descendant?(descendant)
    has_descendant_in_list?(@pieces, descendant)
  end

  # when you graft a substitution into another object,
  # you have to prefix it with the location in that object
  # where you grafted it; but save prefixLength so
  # system property and env variable lookups don 't get
  # broken.
  def relativized(prefix)
    new_pieces = []
    @pieces.each { |p|
      new_pieces << p.relativized(prefix)
    }
    self.class.new(origin, new_pieces)
  end

  def can_equal(other)
    other.is_a? Hocon::Impl::ConfigConcatenation
  end

  def ==(other)
    if other.is_a? Hocon::Impl::ConfigConcatenation
      can_equal(other) && @pieces == other.pieces
    else
      false
    end
  end

  def hash
    # note that "origin" is deliberately NOT part of equality
    @pieces.hash
  end

  def render_value_to_sb(sb, indent, at_root, options)
    @pieces.each do |piece|
      piece.render_value_to_sb(sb, indent, at_root, options)
    end
  end

  private

  def not_resolved
    ConfigNotResolvedError.new("need to Config#resolve(), see the API docs for Config#resolve(); substitution not resolved: #{self}")
  end

  def self.is_ignored_whitespace(value)
    return value.is_a?(ConfigString) && !value.was_quoted?
  end
end
