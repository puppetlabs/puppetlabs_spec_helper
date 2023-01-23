# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_value'
require 'hocon/impl/simple_config'
require 'hocon/config_object'
require 'hocon/config_value_type'
require 'hocon/impl/resolve_status'
require 'hocon/impl/simple_config_origin'
require 'hocon/config_error'
require 'hocon/impl/config_impl'
require 'hocon/impl/unsupported_operation_error'
require 'hocon/impl/container'

module Hocon::Impl::AbstractConfigObject
  include Hocon::ConfigObject
  include Hocon::Impl::Container
  include Hocon::Impl::AbstractConfigValue

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError

  def initialize(origin)
    super(origin)
    @config = Hocon::Impl::SimpleConfig.new(self)
  end

  def to_config
    @config
  end

  def to_fallback_value
    self
  end

  def with_only_key(key)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `with_only_key`"
  end

  def without_key(key)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `without_key`"
  end

  def with_value(key, value)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `with_value`"
  end

  def with_only_path_or_nil(path)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `with_only_path_or_nil`"
  end

  def with_only_path(path)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `with_only_path`"
  end

  def without_path(path)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `without_path`"
  end

  def with_path_value(path, value)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `with_path_value`"
  end

  # This looks up the key with no transformation or type conversion of any
  # kind, and returns null if the key is not present. The object must be
  # resolved along the nodes needed to get the key or
  # ConfigNotResolvedError will be thrown.
  #
  # @param key
  # @return the unmodified raw value or null
  def peek_assuming_resolved(key, original_path)
    begin
      attempt_peek_with_partial_resolve(key)
    rescue ConfigNotResolvedError => e
      raise Hocon::Impl::ConfigImpl.improve_not_resolved(original_path, e)
    end
  end

  # Look up the key on an only-partially-resolved object, with no
  # transformation or type conversion of any kind; if 'this' is not resolved
  # then try to look up the key anyway if possible.
  #
  # @param key
  #            key to look up
  # @return the value of the key, or null if known not to exist
  # @throws ConfigNotResolvedError
  #             if can't figure out key's value (or existence) without more
  #             resolving
  def attempt_peek_with_partial_resolve(key)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `attempt_peek_with_partial_resolve`"
  end

  # Looks up the path with no transformation or type conversion. Returns null
  # if the path is not found; throws ConfigException.NotResolved if we need
  # to go through an unresolved node to look up the path.
  def peek_path(path)
    peek_path_from_obj(self, path)
  end

  def peek_path_from_obj(obj, path)
    begin
      # we'll fail if anything along the path can't be looked at without resolving
      path_next = path.remainder
      v = obj.attempt_peek_with_partial_resolve(path.first)

      if path_next.nil?
        v
      else
        if v.is_a?(Hocon::Impl::AbstractConfigObject)
          peek_path_from_obj(v, path_next)
        else
          nil
        end
      end
    rescue ConfigNotResolvedError => e
      raise Hocon::Impl::ConfigImpl.improve_not_resolved(path, e)
    end
  end

  def value_type
    Hocon::ConfigValueType::OBJECT
  end

  def new_copy_with_status(status, origin)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `new_copy_with_status`"
  end

  def new_copy(origin)
    new_copy_with_status(resolve_status, origin)
  end

  def construct_delayed_merge(origin, stack)
    Hocon::Impl::ConfigDelayedMergeObject.new(origin, stack)
  end

  def merged_with_object(fallback)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `merged_with_object`"
  end

  def with_fallback(mergeable)
    super(mergeable)
  end

  def self.merge_origins(stack)
    if stack.empty?
      raise ConfigBugOrBrokenError, "can't merge origins on empty list"
    end
    origins = []
    first_origin = nil
    num_merged = 0
    stack.each do |v|
      if first_origin.nil?
        first_origin = v.origin
      end

      if (v.is_a?(Hocon::Impl::AbstractConfigObject)) &&
          (v.resolve_status == Hocon::Impl::ResolveStatus::RESOLVED) &&
          v.empty?
        # don't include empty files or the .empty()
        # config in the description, since they are
        # likely to be "implementation details"
      else
        origins.push(v.origin)
        num_merged += 1
      end
    end

    if num_merged == 0
      # the configs were all empty, so just use the first one
      origins.push(first_origin)
    end

    Hocon::Impl::SimpleConfigOrigin.merge_origins(origins)
  end

  def resolve_substitutions(context, source)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `resolve_substituions`"
  end

  def relativized(path)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `relativized`"
  end

  def [](key)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `[]`"
  end

  def render_value_to_sb(sb, indent, at_root, options)
    raise ConfigBugOrBrokenError, "subclasses of AbstractConfigObject should override `render_value_to_sb`"
  end

  def we_are_immutable(method)
    Hocon::Impl::UnsupportedOperationError.new("ConfigObject is immutable, you can't call Map.#{method}")
  end

  def clear
    raise we_are_immutable("clear")
  end

  def []=(key, value)
    raise we_are_immutable("[]=")
  end

  def putAll(map)
    raise we_are_immutable("putAll")
  end

  def remove(key)
    raise we_are_immutable("remove")
  end

  def delete(key)
    raise we_are_immutable("delete")
  end

  def with_origin(origin)
    super(origin)
  end
end
