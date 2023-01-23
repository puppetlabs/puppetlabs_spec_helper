# encoding: utf-8

require 'hocon'
require 'hocon/impl/config_impl'

class Hocon::ConfigValueFactory
  ConfigImpl = Hocon::Impl::ConfigImpl

  #
  # Creates a {@link ConfigValue} from a plain value, which may be
  # a <code>Boolean</code>, <code>Number</code>, <code>String</code>,
  # <code>Hash</code>, or <code>nil</code>. A
  # <code>Hash</code> must be a <code>Hash</code> from String to more values
  # that can be supplied to <code>from_any_ref()</code>. A <code>Hash</code>
  # will become a {@link ConfigObject} and an <code>Array</code> will become a
  # {@link ConfigList}.
  #
  # <p>
  # In a <code>Hash</code> passed to <code>from_any_ref()</code>, the map's keys
  # are plain keys, not path expressions. So if your <code>Hash</code> has a
  # key "foo.bar" then you will get one object with a key called "foo.bar",
  # rather than an object with a key "foo" containing another object with a
  # key "bar".
  #
  # <p>
  # The origin_description will be used to set the origin() field on the
  # ConfigValue. It should normally be the name of the file the values came
  # from, or something short describing the value such as "default settings".
  # The origin_description is prefixed to error messages so users can tell
  # where problematic values are coming from.
  #
  # <p>
  # Supplying the result of ConfigValue.unwrapped() to this function is
  # guaranteed to work and should give you back a ConfigValue that matches
  # the one you unwrapped. The re-wrapped ConfigValue will lose some
  # information that was present in the original such as its origin, but it
  # will have matching values.
  #
  # <p>
  # If you pass in a <code>ConfigValue</code> to this
  # function, it will be returned unmodified. (The
  # <code>origin_description</code> will be ignored in this
  # case.)
  #
  # <p>
  # This function throws if you supply a value that cannot be converted to a
  # ConfigValue, but supplying such a value is a bug in your program, so you
  # should never handle the exception. Just fix your program (or report a bug
  # against this library).
  #
  # @param object
  #            object to convert to ConfigValue
  # @param origin_description
  #            name of origin file or brief description of what the value is
  # @return a new value
  #
  def self.from_any_ref(object, origin_description = nil)
    if object.is_a?(Hash)
      from_map(object, origin_description)
    else
      ConfigImpl.from_any_ref(object, origin_description)
    end
  end

  #
  # See the {@link #from_any_ref(Object,String)} documentation for details
  #
  # <p>
  # See also {@link ConfigFactory#parse_map(Map)} which interprets the keys in
  # the map as path expressions.
  #
  # @param values map from keys to plain ruby values
  # @return a new {@link ConfigObject}
  #
  def self.from_map(values, origin_description = nil)
    ConfigImpl.from_any_ref(process_hash(values), origin_description)
  end

  private

  def self.process_hash(hash)
    Hash[hash.map {|k, v| [k.is_a?(Symbol) ? k.to_s : k, v.is_a?(Hash) ? process_hash(v) : v]}]
  end

end
