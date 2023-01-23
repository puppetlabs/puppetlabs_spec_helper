# encoding: utf-8

require 'hocon'
require 'hocon/impl'
require 'hocon/impl/abstract_config_value'

class Hocon::Impl::ConfigReference
  include Hocon::Impl::Unmergeable
  include Hocon::Impl::AbstractConfigValue

  # Require these lazily, to avoid circular dependencies
  require 'hocon/impl/resolve_source'
  require 'hocon/impl/resolve_result'


  NotPossibleToResolve = Hocon::Impl::AbstractConfigValue::NotPossibleToResolve
  UnresolvedSubstitutionError = Hocon::ConfigError::UnresolvedSubstitutionError

  attr_reader :expr, :prefix_length

  def initialize(origin, expr, prefix_length = 0)
    super(origin)
    @expr = expr
    @prefix_length = prefix_length
  end

  def unmerged_values
    [self]
  end

  # ConfigReference should be a firewall against NotPossibleToResolve going
  # further up the stack; it should convert everything to ConfigException.
  # This way it 's impossible for NotPossibleToResolve to "escape" since
  # any failure to resolve has to start with a ConfigReference.
  def resolve_substitutions(context, source)
    new_context = context.add_cycle_marker(self)
    begin
      result_with_path = source.lookup_subst(new_context, @expr, @prefix_length)
      new_context = result_with_path.result.context

      if result_with_path.result.value != nil
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace(
              "recursively resolving #{result_with_path} which was the resolution of #{expr} against #{source}",
              context.depth)
        end

        recursive_resolve_source = Hocon::Impl::ResolveSource.new(
            result_with_path.path_from_root.last, result_with_path.path_from_root)

        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace("will recursively resolve against #{recursive_resolve_source}", context.depth)
        end

        result = new_context.resolve(result_with_path.result.value,
                                     recursive_resolve_source)
        v = result.value
        new_context = result.context
      else
        v = nil
      end
    rescue NotPossibleToResolve => e
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace(
            "not possible to resolve #{expr}, cycle involved: #{e.trace_string}", new_context.depth)
      end
      if @expr.optional
        v = nil
      else
        raise UnresolvedSubstitutionError.new(
                  origin,
                  "#{@expr} was part of a cycle of substitutions involving #{e.trace_string}", e)
      end
    end

    if v == nil && !@expr.optional
      if new_context.options.allow_unresolved
        ResolveResult.make(new_context.remove_cycle_marker(self), self)
      else
        raise UnresolvedSubstitutionError.new(origin, @expr.to_s)
      end
    else
      Hocon::Impl::ResolveResult.make(new_context.remove_cycle_marker(self), v)
    end

  end

  def value_type
    raise not_resolved
  end

  def unwrapped
    raise not_resolved
  end

  def new_copy(new_origin)
    Hocon::Impl::ConfigReference.new(new_origin, @expr, @prefix_length)
  end

  def ignores_fallbacks?
    false
  end

  def resolve_status
    Hocon::Impl::ResolveStatus::UNRESOLVED
  end

  def relativized(prefix)
    new_expr = @expr.change_path(@expr.path.prepend(prefix))

    Hocon::Impl::ConfigReference.new(origin, new_expr, @prefix_length + prefix.length)
  end

  def can_equal(other)
    other.is_a? Hocon::Impl::ConfigReference
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality
    if other.is_a? Hocon::Impl::ConfigReference
      can_equal(other) && @expr == other.expr
    end
  end

  def hash
    # note that "origin" is deliberately NOT part of equality
    @expr.hash
  end

  def render_value_to_sb(sb, indent, at_root, options)
    sb << @expr.to_s
  end

  def expression
    @expr
  end

  private

  def not_resolved
    error_message = "need to Config#resolve, see the API docs for Config#resolve; substitution not resolved: #{self}"
    Hocon::ConfigError::ConfigNotResolvedError.new(error_message, nil)
  end

end
