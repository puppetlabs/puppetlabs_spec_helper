require 'yaml'
require 'singleton'
require_relative '../../puppet/util/yaml'

# a class for storing state
class Puppet::Util::Storage
  include Singleton
  include Puppet::Util

  def self.state
    @@state
  end

  def initialize
    self.class.load
  end

  # Return a hash that will be stored to disk.  It's worth noting
  # here that we use the object's full path, not just the name/type
  # combination.  At the least, this is useful for those non-isomorphic
  # types like exec, but it also means that if an object changes locations
  # in the configuration it will lose its cache.
  def self.cache(object)
    if object.is_a?(Symbol)
      name = object
    else
      name = object.to_s
    end

    @@state[name] ||= {}
  end

  def self.clear
    @@state.clear
  end

  def self.init
    @@state = {}
  end

  self.init

  def self.load
    Puppet.settings.use(:main) unless FileTest.directory?(Puppet[:statedir])
    filename = Puppet[:statefile]

    unless Puppet::FileSystem.exist?(filename)
      self.init if @@state.nil?
      return
    end
    unless File.file?(filename)
      Puppet.warning(_("Checksumfile %{filename} is not a file, ignoring") % { filename: filename })
      return
    end
    Puppet::Util.benchmark(:debug, "Loaded state in %{seconds} seconds") do
      begin
        @@state = Puppet::Util::Yaml.safe_load_file(filename, [Symbol, Time])
      rescue Puppet::Util::Yaml::YamlLoadError => detail
        Puppet.err _("Checksumfile %{filename} is corrupt (%{detail}); replacing") % { filename: filename, detail: detail }

        begin
          File.rename(filename, filename + ".bad")
        rescue
          raise Puppet::Error, _("Could not rename corrupt %{filename}; remove manually") % { filename: filename }, detail.backtrace
        end
      end
    end

    unless @@state.is_a?(Hash)
      Puppet.err _("State got corrupted")
      self.init
    end
  end

  def self.stateinspect
    @@state.inspect
  end

  def self.store
    Puppet.debug "Storing state"

    Puppet.info _("Creating state file %{file}") % { file: Puppet[:statefile] } unless Puppet::FileSystem.exist?(Puppet[:statefile])

    if Puppet[:statettl] == 0 || Puppet[:statettl] == Float::INFINITY
      Puppet.debug "Not pruning old state cache entries"
    else
      Puppet::Util.benchmark(:debug, "Pruned old state cache entries in %{seconds} seconds") do
        ttl_cutoff = Time.now - Puppet[:statettl]

        @@state.reject! do |k,v|
          @@state[k][:checked] && @@state[k][:checked] < ttl_cutoff
        end
      end
    end

    Puppet::Util.benchmark(:debug, "Stored state in %{seconds} seconds") do
      Puppet::Util::Yaml.dump(@@state, Puppet[:statefile])
    end
  end
end
