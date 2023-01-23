# encoding: utf-8

require 'hocon'
require 'hocon/config_error'
require 'hocon/impl/resolve_source'
require 'hocon/impl/resolve_memos'
require 'hocon/impl/memo_key'
require 'hocon/impl/abstract_config_value'
require 'hocon/impl/config_impl'

class Hocon::Impl::ResolveContext

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  NotPossibleToResolve = Hocon::Impl::AbstractConfigValue::NotPossibleToResolve

  attr_reader :restrict_to_child

  def initialize(memos, options, restrict_to_child, resolve_stack, cycle_markers)
    @memos = memos
    @options = options
    @restrict_to_child = restrict_to_child
    @resolve_stack = resolve_stack
    @cycle_markers = cycle_markers
  end

  def self.new_cycle_markers
    # This looks crazy, but wtf else should we do with
    # return Collections.newSetFromMap(new IdentityHashMap<AbstractConfigValue, Boolean>());
    Set.new
  end

  def add_cycle_marker(value)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("++ Cycle marker #{value}@#{value.hash}",
                       depth)
    end
    if @cycle_markers.include?(value)
      raise ConfigBugOrBrokenError.new("Added cycle marker twice " + value)
    end
    copy = self.class.new_cycle_markers
    copy.merge(@cycle_markers)
    copy.add(value)
    self.class.new(@memos, @options, @restrict_to_child, @resolve_stack, copy)
  end

  def remove_cycle_marker(value)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("-- Cycle marker #{value}@#{value.hash}",
                                    depth)
    end

    copy = self.class.new_cycle_markers
    copy.merge(@cycle_markers)
    copy.delete(value)
    self.class.new(@memos, @options, @restrict_to_child, @resolve_stack, copy)
  end

  def memoize(key, value)
    changed = @memos.put(key, value)
    self.class.new(changed, @options, @restrict_to_child, @resolve_stack, @cycle_markers)
  end

  def options
    @options
  end

  def is_restricted_to_child
    @restrict_to_child != nil
  end

  def restrict(restrict_to)
    if restrict_to.equal?(@restrict_to_child)
      self
    else
      Hocon::Impl::ResolveContext.new(@memos, @options, restrict_to, @resolve_stack, @cycle_markers)
    end
  end

  def unrestricted
    restrict(nil)
  end

  def resolve(original, source)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace(
          "resolving #{original} restrict_to_child=#{@restrict_to_child} in #{source}",
          depth)
    end
    push_trace(original).real_resolve(original, source).pop_trace
  end

  def real_resolve(original, source)
    # a fully-resolved (no restrict_to_child) object can satisfy a
    # request for a restricted object, so always check that first.
    full_key = Hocon::Impl::MemoKey.new(original, nil)
    restricted_key = nil

    cached = @memos.get(full_key)

    # but if there was no fully-resolved object cached, we'll only
    # compute the restrictToChild object so use a more limited
    # memo key
    if cached == nil && is_restricted_to_child
      restricted_key = Hocon::Impl::MemoKey.new(original, @restrict_to_child)
      cached = @memos.get(restricted_key)
    end

    if cached != nil
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace(
            "using cached resolution #{cached} for #{original} restrict_to_child #{@restrict_to_child}",
            depth)
      end
      Hocon::Impl::ResolveResult.make(self, cached)
    else
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace(
            "not found in cache, resolving #{original}@#{original.hash}",
            depth)
      end

      if @cycle_markers.include?(original)
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace(
              "Cycle detected, can't resolve; #{original}@#{original.hash}",
              depth)
        end
        raise NotPossibleToResolve.new(self)
      end

      result = original.resolve_substitutions(self, source)
      resolved = result.value

      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace(
            "resolved to #{resolved}@#{resolved.hash} from #{original}@#{resolved.hash}",
            depth)
      end

      with_memo = result.context

      if resolved == nil || resolved.resolve_status == Hocon::Impl::ResolveStatus::RESOLVED
        # if the resolved object is fully resolved by resolving
        # only the restrictToChildOrNull, then it can be cached
        # under fullKey since the child we were restricted to
        # turned out to be the only unresolved thing.
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace(
              "caching #{full_key} result #{resolved}",
              depth)
        end

        with_memo = with_memo.memoize(full_key, resolved)
      else
        # if we have an unresolved object then either we did a
        # partial resolve restricted to a certain child, or we are
        # allowing incomplete resolution, or it's a bug.
        if is_restricted_to_child
          if restricted_key == nil
            raise ConfigBugOrBrokenError.new("restricted_key should not be null here")
          end
          if Hocon::Impl::ConfigImpl.trace_substitution_enabled
            Hocon::Impl::ConfigImpl.trace(
                "caching #{restricted_key} result #{resolved}",
                depth)
          end

          with_memo = with_memo.memoize(restricted_key, resolved)
        elsif @options.allow_unresolved
          if Hocon::Impl::ConfigImpl.trace_substitution_enabled
            Hocon::Impl::ConfigImpl.trace(
                "caching #{full_key} result #{resolved}",
                depth)
          end

          with_memo = with_memo.memoize(full_key, resolved)
        else
          raise ConfigBugOrBrokenError.new(
                    "resolve_substitutions did not give us a resolved object")
        end
      end
      Hocon::Impl::ResolveResult.make(with_memo, resolved)
    end
  end

  # This method is a translation of the constructor in the Java version with signature
  # ResolveContext(ConfigResolveOptions options, Path restrictToChild)
  def self.construct(options, restrict_to_child)
    context = self.new(Hocon::Impl::ResolveMemos.new,
                       options,
                       restrict_to_child,
                       [],
                       new_cycle_markers)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace(
          "ResolveContext restrict to child #{restrict_to_child}", context.depth)
    end
    context
  end

  def trace_string
    separator = ", "
    sb = ""
    @resolve_stack.each { |value|
      if value.instance_of?(Hocon::Impl::ConfigReference)
        sb << value.expression.to_s
        sb << separator
      end
    }
    if sb.length > 0
      sb.chomp!(separator)
    end
    sb
  end

  def depth
    if @resolve_stack.size > 30
      raise Hocon::ConfigError::ConfigBugOrBrokenError.new("resolve getting too deep")
    end
    @resolve_stack.size
  end

  def self.resolve(value, root, options)
    source = Hocon::Impl::ResolveSource.new(root)
    context = construct(options, nil)
    begin
      context.resolve(value, source).value
    rescue NotPossibleToResolve => e
      # ConfigReference was supposed to catch NotPossibleToResolve
      raise ConfigBugOrBrokenError(
                "NotPossibleToResolve was thrown from an outermost resolve", e)
    end
  end

  def pop_trace
    copy = @resolve_stack.clone
    old = copy.delete_at(@resolve_stack.size - 1)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("popped trace #{old}", depth - 1)
    end
    Hocon::Impl::ResolveContext.new(@memos, @options, @restrict_to_child, copy, @cycle_markers)
  end

  private

  def push_trace(value)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("pushing trace #{value}", depth)
    end
    copy = @resolve_stack.clone
    copy << value
    Hocon::Impl::ResolveContext.new(@memos, @options, @restrict_to_child, copy, @cycle_markers)
  end
end
