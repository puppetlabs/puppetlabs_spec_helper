# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/simple_includer'
require 'hocon/config_error'
require 'hocon/impl/from_map_mode'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/simple_config_list'
require 'hocon/impl/config_boolean'
require 'hocon/impl/config_null'
require 'hocon/impl/parseable'

class Hocon::Impl::ConfigImpl
  @default_includer = Hocon::Impl::SimpleIncluder.new(nil)
  @default_value_origin = Hocon::Impl::SimpleConfigOrigin.new_simple("hardcoded value")
  @default_true_value = Hocon::Impl::ConfigBoolean.new(@default_value_origin, true)
  @default_false_value = Hocon::Impl::ConfigBoolean.new(@default_value_origin, false)
  @default_null_value = Hocon::Impl::ConfigNull.new(@default_value_origin)
  @default_empty_list = Hocon::Impl::SimpleConfigList.new(@default_value_origin, Array.new)
  @default_empty_object = Hocon::Impl::SimpleConfigObject.empty(@default_value_origin)


  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError
  FromMapMode = Hocon::Impl::FromMapMode

  def self.default_includer
    @default_includer
  end


  class FileNameSource < Hocon::Impl::SimpleIncluder::NameSource
    def name_to_parseable(name, parse_options)
      Hocon::Impl::Parseable.new_file(name, parse_options)
    end
  end

  def self.improve_not_resolved(what, original)
    new_message = "#{what.render} has not been resolved, you need to call Config#resolve, see API docs for Config#resolve"
    if new_message == original.message
      return original
    else
      return ConfigNotResolvedError.new(new_message, original)
    end
  end

  def self.value_origin(origin_description)
    if origin_description.nil?
      return @default_value_origin
    else
      return Hocon::Impl::SimpleConfigOrigin.new_simple(origin_description)
    end
  end

  def self.parse_file_any_syntax(basename, base_options)
    source = FileNameSource.new()
    Hocon::Impl::SimpleIncluder.from_basename(source,
                                              File.expand_path(basename),
                                              base_options)
  end

  def self.empty_list(origin)
    if origin.nil? || origin == @default_value_origin
      return @default_empty_list
    else
      return Hocon::Impl::SimpleConfigList.new(origin, Array.new)
    end
  end

  def self.from_any_ref(object, origin_description)
    origin = self.value_origin(origin_description)
    from_any_ref_mode(object, origin, FromMapMode::KEYS_ARE_KEYS)
  end

  def self.from_any_ref_mode(object, origin, map_mode)
    if origin.nil?
      raise ConfigBugOrBrokenError.new("origin not supposed to be nil")
    end
    if object.nil?
      if origin != @default_value_origin
        return Hocon::Impl::ConfigNull.new(origin)
      else
        return @default_null_value
      end
    elsif object.is_a?(Hocon::Impl::AbstractConfigValue)
      return object
    elsif object.is_a?(TrueClass) || object.is_a?(FalseClass)
      if origin != @default_value_origin
        return Hocon::Impl::ConfigBoolean.new(origin, object)
      elsif object
        return @default_true_value
      else
        return @default_false_value
      end
    elsif object.is_a?(String)
      return Hocon::Impl::ConfigString::Quoted.new(origin, object)
    elsif object.is_a?(Numeric)
      # here we always keep the same type that was passed to us,
      # rather than figuring out if a Long would fit in an Int
      # or a Double has no fractional part. i.e. deliberately
      # not using ConfigNumber.newNumber() when we have a
      # Double, Integer, or Long.
      if object.is_a?(Float)
        return Hocon::Impl::ConfigDouble.new(origin, object, nil)
      elsif object.is_a?(Integer)
        return Hocon::Impl::ConfigInt.new(origin, object, nil)
      else
        return Hocon::Impl::ConfigNumber.new_number(origin, Float(object), nil)
      end
    elsif object.is_a?(Hash)
      if object.empty?
        return self.empty_object_from_origin(origin)
      end

      if map_mode == FromMapMode::KEYS_ARE_KEYS
        values = Hash.new
        object.each do |key, entry|
          if not key.is_a?(String)
            raise ConfigBugOrBrokenError.new(
                      "bug in method caller: not valid to create ConfigObject from map with non-String key: #{key}")
          end
          value = self.from_any_ref_mode(entry, origin, map_mode)
          values[key] = value
        end
        return Hocon::Impl::SimpleConfigObject.new(origin, values)
      else
        raise ConfigBugOrBrokenError, "java properties format not supported"
      end
    elsif object.is_a?(Enumerable)
      if object.count == 0
        return self.empty_list(origin)
      end

      values = Array.new
      object.each do |item|
        v = from_any_ref_mode(item, origin, map_mode)
        values.push(v)
      end

      return Hocon::Impl::SimpleConfigList.new(origin, values)
    else
      raise ConfigBugOrBrokenError.new("bug in method caller: not valid to create ConfigValue from: #{object}")
    end
  end



  def self.env_variables_as_config_object
    EnvVariablesHolder.get_env_variables
  end

  # This class is a lot simpler than the Java version ...
  # The Java version uses system properties to toggle these settings.
  # We don't have system properties in MRI so it's not clear what to do here.
  # Initially, I ported this as more of a direct translation from the Java code,
  # but I ran into issues around how to translate stupid Java static
  # initialization crap to Ruby, so what we have here is a much simpler version
  # that is # equivalent.
  #
  # There's no way to toggle this logging without changing code, but it's
  # actually proved to be useful for debugging purposes while porting code
  # down from Java.
  class DebugHolder
    class << self

      def trace_loads_enabled
        TRACE_LOADS_ENABLED
      end

      def trace_substitutions_enabled
        TRACE_SUBSTITUTIONS_ENABLED
      end

      private

      TRACE_LOADS_ENABLED = false
      TRACE_SUBSTITUTIONS_ENABLED = false
    end
  end

  def self.trace_loads_enabled
    # Ignoring 'catch ExceptionInInitializerError' from that java version,
    # that is just terrible java code anyway.
    DebugHolder.trace_loads_enabled
  end

  def self.trace_substitution_enabled
    # Ignoring 'catch ExceptionInInitializerError' from that java version,
    # that is just terrible java code anyway.
    DebugHolder.trace_substitutions_enabled
  end

  def self.trace(message, indent_level = 0)
    while indent_level > 0
      $stderr.putc(" ")
      indent_level -= 1
    end
    $stderr.puts(message)
  end

  def self.empty_object_from_origin(origin)
    # we want null origin to go to SimpleConfigObject.empty() to get the
    # origin "empty config" rather than "hardcoded value"
    if origin == @default_value_origin
      @default_empty_object
    else
      Hocon::Impl::SimpleConfigObject.empty(origin)
    end
  end

  def self.empty_object(origin_description)
    if !origin_description.nil?
      origin = Hocon::Impl::SimpleConfigOrigin.new_simple(origin_description)
    else
      origin = nil
    end

    empty_object_from_origin(origin)
  end

  def self.empty_config(origin_description)
    empty_object(origin_description).to_config
  end

  def empty(origin)
    self.class.empty_object_from_origin(origin)
  end

  def self.default_reference
    resource = Hocon::Impl::Parseable.new_resources("reference.conf",
                                                    Hocon::ConfigParseOptions.defaults)
    resource.parse.to_config
  end

  private

  def self.load_env_variables
    env = ENV
    m = {}
    lists = {}
    env.each do |key, value|
      m[key] = Hocon::Impl::ConfigString::Quoted.new(
          Hocon::Impl::SimpleConfigOrigin.new_simple("env var #{key}"), value)
      # find env var arrays specified like FOO.0, FOO.1
      if key =~ /^(.*)\.(\d+)$/
        name, index = $1, Integer($2)
        # values are added unordered
        (lists[name] ||= {})[index] = value
      end
    end

    lists.each do |key, values|
      origin = Hocon::Impl::SimpleConfigOrigin.new_simple("env var list #{key}")
      m[key] = Hocon::Impl::SimpleConfigList.new(
        origin,
        # out of order env vars FOO.1, FOO.0 are sorted here
        values.sort.map do |v|
          Hocon::Impl::ConfigString::Quoted.new(origin, v[1])
        end
      )
    end

    Hocon::Impl::SimpleConfigObject.new(
        Hocon::Impl::SimpleConfigOrigin.new_simple("env variables"),
        m,
        Hocon::Impl::ResolveStatus::RESOLVED,
        false)
  end

  class EnvVariablesHolder
    ENV_VARIABLES = Hocon::Impl::ConfigImpl.load_env_variables

    def self.get_env_variables
      ENV_VARIABLES
    end
  end
end
