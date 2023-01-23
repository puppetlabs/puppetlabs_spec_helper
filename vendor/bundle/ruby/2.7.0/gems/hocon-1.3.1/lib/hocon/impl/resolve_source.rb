# encoding: utf-8

require 'hocon'
require 'hocon/config_error'
require 'hocon/impl'
require 'hocon/impl/config_impl'
require 'hocon/impl/container'

class Hocon::Impl::ResolveSource

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError

  # 'path_from_root' is used for knowing the chain of parents we used to get here.
  # null if we should assume we are not a descendant of the root.
  # the root itself should be a node in this if non-null.

  attr_accessor :root, :path_from_root

  def initialize(root, path_from_root = nil)
    @root = root
    @path_from_root = path_from_root
  end

  # as a side effect, findInObject() will have to resolve all parents of the
  # child being peeked, but NOT the child itself.Caller has to resolve
  # the child itself if needed.ValueWithPath.value can be null but
  # the ValueWithPath instance itself should not be.
  def find_in_object(obj, context, path)
    # resolve ONLY portions of the object which are along our path
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("*** finding '#{path}' in #{obj}")
    end
    restriction = context.restrict_to_child
    partially_resolved = context.restrict(path).resolve(obj, self.class.new(obj))
    new_context = partially_resolved.context.restrict(restriction)
    if partially_resolved.value.is_a?(Hocon::Impl::AbstractConfigObject)
      pair = self.class.find_in_object_impl(partially_resolved.value, path)
      ResultWithPath.new(Hocon::Impl::ResolveResult.make(new_context, pair.value), pair.path_from_root)
    else
      raise ConfigBugOrBrokenError.new("resolved object to non-object " + obj + " to " + partially_resolved)
    end
  end

  def lookup_subst(context, subst, prefix_length)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("searching for #{subst}", context.depth)
    end

    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("#{subst} - looking up relative to file it occurred in",
                                    context.depth)
    end
    # First we look up the full path, which means relative to the
    # included file if we were not a root file
    result = find_in_object(@root, context, subst.path)

    if result.result.value == nil
      # Then we want to check relative to the root file.We don 't
      # want the prefix we were included at to be used when looking
      # up env variables either.
      unprefixed = subst.path.sub_path_to_end(prefix_length)

      if prefix_length > 0
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace(
              unprefixed + " - looking up relative to parent file",
              result.result.context.depth)
        end
        result = find_in_object(@root, result.result.context, unprefixed)
      end

      if result.result.value == nil && result.result.context.options.use_system_environment
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace(
              "#{unprefixed} - looking up in system environment",
              result.result.context.depth)
        end
        result = find_in_object(Hocon::Impl::ConfigImpl.env_variables_as_config_object, context, unprefixed)
      end
    end

    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace(
          "resolved to #{result}",
          result.result.context.depth)
    end

    result
  end

  def push_parent(parent)
    unless parent
      raise ConfigBugOrBrokenError.new("can't push null parent")
    end

    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("pushing parent #{parent} ==root #{(parent == root)} onto #{self}")
    end

    if @path_from_root == nil
      if parent.equal?(@root)
        return self.class.new(@root, Node.new(parent))
      else
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          # this hasDescendant check is super-expensive so it's a
          # trace message rather than an assertion
          if @root.has_descendant?(parent)
            Hocon::Impl::ConfigImpl.trace(
                "***** BUG ***** tried to push parent #{parent} without having a path to it in #{self}")
          end
        end
        # ignore parents if we aren't proceeding from the
        # root
        return self
      end
    else
      parent_parent = @path_from_root.head
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        # this hasDescendant check is super-expensive so it's a
        # trace message rather than an assertion
        if parent_parent != nil && !parent_parent.has_descendant?(parent)
          Hocon::Impl::ConfigImpl.trace(
              "***** BUG ***** trying to push non-child of #{parent_parent}, non-child was #{parent}")
        end
      end

      self.class.new(@root, @path_from_root.prepend(parent))
    end
  end

  def reset_parents
    if @path_from_root == nil
      this
    else
      self.class.new(@root)
    end
  end

  def replace_current_parent(old, replacement)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("replaceCurrentParent old #{old}@#{old.hash} replacement " +
                                        "#{replacement}@#{old.hash} in #{self}")
    end
    if old.equal?(replacement)
      self
    elsif @path_from_root != nil
      new_path = self.class.replace(@path_from_root, old, replacement)
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace("replaced #{old} with #{replacement} in #{self}")
        Hocon::Impl::ConfigImpl.trace("path was: #{@path_from_root} is now #{new_path}")
      end
      # if we end up nuking the root object itself, we replace it with an
      # empty root
      if new_path != nil
        return self.class.new(new_path.last, new_path)
      else
        return self.class.new(Hocon::Impl::SimpleConfigObject.empty)
      end
    else
      if old.equal?(@root)
        return self.class.new(root_must_be_obj(replacement))
      else
        raise ConfigBugOrBrokenError.new("attempt to replace root #{root} with #{replacement}")
      end
    end
  end

  # replacement may be null to delete
  def replace_within_current_parent(old, replacement)
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("replaceWithinCurrentParent old #{old}@#{old.hash}" +
                                        " replacement #{replacement}@#{old.hash} in #{self}")
    end
    if old.equal?(replacement)
      self
    elsif @path_from_root != nil
      parent = @path_from_root.head
      new_parent = parent.replace_child(old, replacement)
      return replace_current_parent(parent, new_parent.is_a?(Hocon::Impl::Container) ? new_parent : nil)
    else
      if old.equal?(@root) && replacement.is_a?(Hocon::Impl::Container)
        return self.class.new(root_must_be_obj(replacement))
      else
        raise ConfigBugOrBrokenError.new("replace in parent not possible #{old} with #{replacement}" +
                                             " in #{self}")
      end
    end
  end

  def to_s
    "ResolveSource(root=#{@root}, pathFromRoot=#{@path_from_root})"
  end

  # a persistent list
  class Node
    attr_reader :next_node, :value

    def initialize(value, next_node = nil)
      @value = value
      @next_node = next_node
    end

    def prepend(value)
      Node.new(value, self)
    end

    def head
      @value
    end

    def tail
      @next_node
    end

    def last
      i = self
      while i.next_node != nil
        i = i.next_node
      end
      i.value
    end

    def reverse
      if @next_node == nil
        self
      else
        reversed = Node.new(@value)
        i = @next_node
        while i != nil
          reversed = reversed.prepend(i.value)
          i = i.next_node
        end
        reversed
      end
    end

    def to_s
      sb = ""
      sb << "["
      to_append_value = self.reverse
      while to_append_value != nil
        sb << to_append_value.value.to_s
        if to_append_value.next_node != nil
          sb << " <= "
        end
        to_append_value = to_append_value.next_node
      end
      sb << "]"
      sb
    end
  end

  # value is allowed to be null
  class ValueWithPath
    attr_reader :value, :path_from_root

    def initialize(value, path_from_root)
      @value = value
      @path_from_root = path_from_root
    end

    def to_s
      "ValueWithPath(value=" + @value + ", pathFromRoot=" + @path_from_root + ")"
    end
  end

  class ResultWithPath
    attr_reader :result, :path_from_root

    def initialize(result, path_from_root)
      @result = result
      @path_from_root = path_from_root
    end

    def to_s
      "ResultWithPath(result=#{@result}, pathFromRoot=#{@path_from_root})"
    end
  end

  private

  def root_must_be_obj(value)
    if value.is_a?(Hocon::Impl::AbstractConfigObject)
      value
    else
      Hocon::Impl::SimpleConfigObject.empty
    end
  end
  
  def self.find_in_object_impl(obj, path, parents = nil)
    begin
      # we 'll fail if anything along the path can' t
      # be looked at without resolving.
      find_in_object_impl_impl(obj, path, nil)
    rescue ConfigNotResolvedError => e
      raise Hocon::Impl::ConfigImpl.improve_not_resolved(path, e)
    end
  end

  def self.find_in_object_impl_impl(obj, path, parents)
    key = path.first
    remainder = path.remainder
    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("*** looking up '#{key}' in #{obj}")
    end
    v = obj.attempt_peek_with_partial_resolve(key)
    new_parents = parents == nil ? Node.new(obj) : parents.prepend(obj)

    if remainder == nil
      ValueWithPath.new(v, new_parents)
    else
      if v.is_a?(Hocon::Impl::AbstractConfigObject)
        find_in_object_impl_impl(v, remainder, new_parents)
      else
        ValueWithPath.new(nil, new_parents)
      end
    end
  end

  # returns null if the replacement results in deleting all the nodes.
  def self.replace(list, old, replacement)
    child = list.head
    unless child.equal?(old)
      raise ConfigBugOrBrokenError.new("Can only replace() the top node we're resolving; had " + child +
                                           " on top and tried to replace " + old + " overall list was " + list)
    end
    parent = list.tail == nil ? nil : list.tail.head
    if replacement == nil || !replacement.is_a?(Hocon::Impl::Container)
      if parent == nil
        return nil
      else
        # we are deleting the child from the stack of containers
        # because it's either going away or not a container
        new_parent = parent.replace_child(old, nil)

        return replace(list.tail, parent, new_parent)
      end
    else
      # we replaced the container with another container
      if parent == nil
        return Node.new(replacement)
      else
        new_parent = parent.replace_child(old, replacement)
        new_tail = replace(list.tail, parent, new_parent)
        if new_tail != nil
          return new_tail.prepend(replacement)
        else
          return Node.new(replacement)
        end
      end
    end
  end
end
