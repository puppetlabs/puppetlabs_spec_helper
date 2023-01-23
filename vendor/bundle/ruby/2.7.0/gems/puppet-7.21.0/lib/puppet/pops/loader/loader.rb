# Loader
# ===
# A Loader is responsible for loading "entities" ("instantiable and executable objects in the puppet language" which
# are type, hostclass, definition, function, and bindings.
#
# The main method for users of a Loader is the `load` or `load_typed methods`, which returns a previously loaded entity
# of a given type/name, and searches and loads the entity if not already loaded.
#
# private entities
# ---
# TODO: handle loading of entities that are private. Suggest that all calls pass an origin_loader (the loader
# where request originated (or symbol :public). A module loader has one (or possibly a list) of what is
# considered to represent private loader - i.e. the dependency loader for a module. If an entity is private
# it should be stored with this status, and an error should be raised if the origin_loader is not on the list
# of accepted "private" loaders.
# The private loaders can not be given at creation time (they are parented by the loader in question). Another
# alternative is to check if the origin_loader is a child loader, but this requires bidirectional links
# between loaders or a search if loader with private entity is a parent of the origin_loader).
#
# @api public
#
module Puppet::Pops
module Loader

ENVIRONMENT = 'environment'.freeze
ENVIRONMENT_PRIVATE = 'environment private'.freeze

class Loader
  attr_reader :environment, :loader_name

  # Describes the kinds of things that loaders can load
  LOADABLE_KINDS = [:func_4x, :func_4xpp, :func_3x, :datatype, :type_pp, :resource_type_pp, :plan, :task].freeze

  # @param [String] name the name of the loader. Must be unique among all loaders maintained by a {Loader} instance
  def initialize(loader_name, environment)
    @loader_name = loader_name.freeze
    @environment = environment
  end

  # Search all places where this loader would find values of a given type and return a list the
  # found values for which the given block returns true. All found entries will be returned if no
  # block is given.
  #
  # Errors that occur function discovery will either be logged as warnings or collected by the optional
  # `error_collector` array. When provided, it will receive {Puppet::DataTypes::Error} instances describing
  # each error in detail and no warnings will be logged.
  #
  # @param type [Symbol] the type of values to search for
  # @param error_collector [Array<Puppet::DataTypes::Error>] an optional array that will receive errors during load
  # @param name_authority [String] the name authority, defaults to the pcore runtime
  # @yield [typed_name] optional block to filter the results
  # @yieldparam [TypedName] typed_name the typed name of a found entry
  # @yieldreturn [Boolean] `true` to keep the entry, `false` to discard it.
  # @return [Array<TypedName>] the list of names of discovered values
  def discover(type, error_collector = nil, name_authority = Pcore::RUNTIME_NAME_AUTHORITY, &block)
    return EMPTY_ARRAY
  end

  # Produces the value associated with the given name if already loaded, or available for loading
  # by this loader, one of its parents, or other loaders visible to this loader.
  # This is the method an external party should use to "get" the named element.
  #
  # An implementor of this method should first check if the given name is already loaded by self, or a parent
  # loader, and if so return that result. If not, it should call `find` to perform the loading.
  #
  # @param type [:Symbol] the type to load
  # @param name [String, Symbol]  the name of the entity to load
  # @return [Object, nil] the value or nil if not found
  #
  # @api public
  #
  def load(type, name)
    synchronize do
      result = load_typed(TypedName.new(type, name.to_s))
      if result
        result.value
      end
    end
  end

  # Loads the given typed name, and returns a NamedEntry if found, else returns nil.
  # This the same a `load`, but returns a NamedEntry with origin/value information.
  #
  # @param typed_name [TypedName] - the type, name combination to lookup
  # @return [NamedEntry, nil] the entry containing the loaded value, or nil if not found
  #
  # @api public
  #
  def load_typed(typed_name)
    raise NotImplementedError, "Class #{self.class.name} must implement method #load_typed"
  end

  # Returns an already loaded entry if one exists, or nil. This does not trigger loading
  # of the given type/name.
  #
  # @param typed_name [TypedName] - the type, name combination to lookup
  # @param check_dependencies [Boolean] - if dependencies should be checked in addition to here and parent
  # @return [NamedEntry, nil] the entry containing the loaded value, or nil if not found
  # @api public
  #
  def loaded_entry(typed_name, check_dependencies = false)
    raise NotImplementedError, "Class #{self.class.name} must implement method #loaded_entry"
  end

  # Produces the value associated with the given name if defined **in this loader**, or nil if not defined.
  # This lookup does not trigger any loading, or search of the given name.
  # An implementor of this method may not search or look up in any other loader, and it may not
  # define the name.
  #
  # @param typed_name [TypedName] - the type, name combination to lookup
  #
  # @api private
  #
  def [](typed_name)
    found = get_entry(typed_name)
    if found
      found.value
    else
      nil
    end
  end

  # Searches for the given name in this loader's context (parents should already have searched their context(s) without
  # producing a result when this method is called).
  # An implementation of find typically caches the result.
  #
  # @param typed_name [TypedName] the type, name combination to lookup
  # @return [NamedEntry, nil] the entry for the loaded entry, or nil if not found
  #
  # @api private
  #
  def find(typed_name)
    raise NotImplementedError, "Class #{self.class.name} must implement method #find"
  end

  # Returns the parent of the loader, or nil, if this is the top most loader. This implementation returns nil.
  def parent
    nil
  end

  # Produces the private loader for loaders that have a one (the visibility given to loaded entities).
  # For loaders that does not provide a private loader, self is returned.
  #
  # @api private
  def private_loader
    self
  end

  # Lock around a block
  # This exists so some subclasses that are set up statically and don't actually
  # load can override it
  def synchronize(&block)
    @environment.lock.synchronize(&block)
  end

  # Binds a value to a name. The name should not start with '::', but may contain multiple segments.
  #
  # @param type [:Symbol] the type of the entity being set
  # @param name [String, Symbol] the name of the entity being set
  # @param origin [URI, #uri, String] the origin of the set entity, a URI, or provider of URI, or URI in string form
  # @return [NamedEntry, nil] the created entry
  #
  # @api private
  #
  def set_entry(type, name, value, origin = nil)
    raise NotImplementedError.new
  end

  # Produces a NamedEntry if a value is bound to the given name, or nil if nothing is bound.
  #
  # @param typed_name [TypedName] the type, name combination to lookup
  # @return [NamedEntry, nil] the value bound in an entry
  #
  # @api private
  #
  def get_entry(typed_name)
    raise NotImplementedError.new
  end

  # A loader is by default a loader for all kinds of loadables. An implementation may override
  # if it cannot load all kinds.
  #
  # @api private
  def loadables
    LOADABLE_KINDS
  end

  # A loader may want to implement its own version with more detailed information.
  def to_s
    loader_name
  end

  # Loaders may contain references to the environment they load items within.
  # Consequently, calling Kernel#inspect may return strings that are large
  # enough to cause OutOfMemoryErrors on some platforms.
  #
  # We do not call alias_method here as that would copy the content of to_s
  # at this point to inspect (ie children would print out `loader_name`
  # rather than their version of to_s if they chose to implement it).
  def inspect
    self.to_s
  end


  # An entry for one entity loaded by the loader.
  #
  class NamedEntry
    attr_reader :typed_name
    attr_reader :value
    attr_reader :origin

    def initialize(typed_name, value, origin)
      @typed_name = typed_name
      @value = value
      @origin = origin
      freeze()
    end
  end
end
end
end
