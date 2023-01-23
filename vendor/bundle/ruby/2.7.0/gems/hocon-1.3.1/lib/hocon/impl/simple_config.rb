# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_value_type'
require 'hocon/config_resolve_options'
require 'hocon/impl/path'
require 'hocon/impl/default_transformer'
require 'hocon/impl/config_impl'
require 'hocon/impl/resolve_context'
require 'hocon/config_mergeable'

class Hocon::Impl::SimpleConfig
  include Hocon::ConfigMergeable

  ConfigMissingError = Hocon::ConfigError::ConfigMissingError
  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError
  ConfigNullError = Hocon::ConfigError::ConfigNullError
  ConfigWrongTypeError = Hocon::ConfigError::ConfigWrongTypeError
  ConfigValueType = Hocon::ConfigValueType
  Path = Hocon::Impl::Path
  DefaultTransformer = Hocon::Impl::DefaultTransformer

  attr_reader :object

  def initialize(object)
    @object = object
  end
  attr_reader :object

  def root
    @object
  end

  def origin
    @object.origin
  end

  def resolve(options = Hocon::ConfigResolveOptions.defaults)
    resolve_with(self, options)
  end

  def resolve_with(source, options)
    resolved = Hocon::Impl::ResolveContext.resolve(@object, source.object, options)
    if resolved.eql?(@object)
      self
    else
      Hocon::Impl::SimpleConfig.new(resolved)
    end
  end

  def self.find_key(me, key, expected, original_path)
    v = me.peek_assuming_resolved(key, original_path)
    if v.nil?
      raise ConfigMissingError.new(nil, "No configuration setting found for key '#{original_path.render}'", nil)
    end

    if not expected.nil?
      v = DefaultTransformer.transform(v, expected)
    end

    if v.value_type == ConfigValueType::NULL
      raise ConfigNullError.new(v.origin,
                                (ConfigNullError.make_message(original_path.render,
                                                              (not expected.nil?) ? ConfigValueType.value_type_name(expected) : nil)),
                                nil)
    elsif (not expected.nil?) && v.value_type != expected
      raise ConfigWrongTypeError.new(v.origin,
                                     "#{original_path.render} has type #{ConfigValueType.value_type_name(v.value_type)} " +
                                         "rather than #{ConfigValueType.value_type_name(expected)}",
                                     nil)
    else
      return v
    end
  end

  def find(me, path, expected, original_path)
    key = path.first
    rest = path.remainder
    if rest.nil?
      self.class.find_key(me, key, expected, original_path)
    else
      o = self.class.find_key(me, key, ConfigValueType::OBJECT,
                   original_path.sub_path(0, original_path.length - rest.length))
      raise "Error: object o is nil" unless not o.nil?
      find(o, rest, expected, original_path)
    end
  end

  def find3(path_expression, expected, original_path)
    find(@object, path_expression, expected, original_path)
  end

  def find2(path_expression, expected)
    path = Path.new_path(path_expression)
    find3(path, expected, path)
  end

  def ==(other)
    if other.is_a? Hocon::Impl::SimpleConfig
      @object == other.object
    else
      false
    end
  end

  def hash
    41 * @object.hash
  end

  def self.find_key_or_null(me, key, expected, original_path)
    v = me.peek_assuming_resolved(key, original_path)

    if v.nil?
      raise Hocon::ConfigError::ConfigMissingError.new(nil, original_path.render, nil)
    end

    if not expected.nil?
      v = Hocon::Impl::DefaultTransformer.transform(v, expected)
    end

    if (not expected.nil?) && (v.value_type != expected && v.value_type != ConfigValueType::NULL)
      raise Hocon::ConfigError::ConfigWrongTypeError.with_expected_actual(v.origin,
                                                                          original_path.render,
                                                                          ConfigValueType.value_type_name(expected),         
                                                                          ConfigValueType.value_type_name(v.value_type))
    else
      return v
    end
  end

  def self.find_or_null(me, path, expected, original_path)
    begin
      key = path.first
      remainder = path.remainder

      if remainder.nil?
        return self.find_key_or_null(me, key, expected, original_path)
      else
        o = find_key(me,
                     key,
                     ConfigValueType::OBJECT,
                     original_path.sub_path(0, original_path.length - remainder.length))

        if o.nil?
          raise "Missing key: #{key} on path: #{path}"
        end

        find_or_null(o, remainder, expected, original_path)
      end
    rescue Hocon::ConfigError::ConfigNotResolvedError
      raise Hocon::Impl::ConfigImpl::improved_not_resolved(path, e)
    end
  end

  def is_null?(path_expression)
    path = Path.new_path(path_expression)
    v = self.class.find_or_null(@object, path, nil, path)
    v.value_type == ConfigValueType::NULL
  end

  def get_value(path)
    parsed_path = Path.new_path(path)
    find(@object, parsed_path, nil, parsed_path)
  end

  def get_boolean(path)
    v = find2(path, ConfigValueType::BOOLEAN)
    v.unwrapped
  end

  def get_config_number(path_expression)
    path = Path.new_path(path_expression)
    v = find(@object, path, ConfigValueType::NUMBER, path)
    v.unwrapped
  end

  def get_int(path)
    get_config_number(path)
  end

  def get_string(path)                                                                                                                                                                                                                                                
    v = find2(path, ConfigValueType::STRING)
    v.unwrapped
  end

  def get_list(path)
    find2(path, ConfigValueType::LIST)
  end

  def get_object(path)
    find2(path, ConfigValueType::OBJECT)
  end

  def get_config(path)
    get_object(path).to_config
  end

  def get_any_ref(path)
    v = find2(path, nil)
    v.unwrapped
  end

  def get_bytes(path)
    size = null
    begin
      size = get_long(path)
    rescue ConfigWrongTypeError => e
      v = find2(path, ConfigValueType::STRING)
      size = self.class.parse_bytes(v.unwrapped, v.origin, path)
    end
    size
  end

  def get_homogeneous_unwrapped_list(path, expected)
    l = []
    list = get_list(path)
    list.each do |cv|
      if !expected.nil?
        v = DefaultTransformer.transform(cv, expected)
      end
      if v.value_type != expected
        raise ConfigWrongTypeError.with_expected_actual(origin, path,
              "list of #{ConfigValueType.value_type_name(expected)}",
              "list of #{ConfigValueType.value_type_name(v.value_type)}")
      end
      l << v.unwrapped
    end
    l
  end

  def get_boolean_list(path)
    get_homogeneous_unwrapped_list(path, ConfigValueType::BOOLEAN)
  end

  def get_number_list(path)
    get_homogeneous_unwrapped_list(path, ConfigValueType::NUMBER)
  end

  def get_int_list(path)
    l = []
    numbers = get_homogeneous_wrapped_list(path, ConfigValueType::NUMBER)
    numbers.each do |v|
      l << v.int_value_range_checked(path)
    end
    l
  end

  def get_double_list(path)
    l = []
    numbers = get_number_list(path)
    numbers.each do |n|
      l << n.double_value
    end
    l
  end

  def get_string_list(path)
    get_homogeneous_unwrapped_list(path, ConfigValueType::STRING)
  end

  def get_object_list(path)
    get_homogeneous_wrapped_list(path, ConfigValueType::OBJECT)
  end

  def get_homogeneous_wrapped_list(path, expected)
    l = []
    list = get_list(path)
    list.each do |cv|
      if !expected.nil?
        v = DefaultTransformer.transform(cv, expected)
      end
      if v.value_type != expected
        raise ConfigWrongTypeError.with_expected_actual(origin, path,
                                                        "list of #{ConfigValueType.value_type_name(expected)}",
                                                        "list of #{ConfigValueType.value_type_name(v.value_type)}")
      end
      l << v
    end
    l
  end

  def has_path_peek(path_expression)
    path = Path.new_path(path_expression)

    begin
      peeked = @object.peek_path(path)
    rescue Hocon::ConfigError::ConfigNotResolvedError
      raise Hocon::Impl::ConfigImpl.improved_not_resolved(path, e)
    end

    peeked
  end

  def has_path?(path_expression)
    peeked = has_path_peek(path_expression)

    (not peeked.nil?) && peeked.value_type != ConfigValueType::NULL
  end

  def has_path_or_null?(path)
    peeked = has_path_peek(path)

    not peeked.nil?
  end

  def empty?
    @object.empty?
  end

  def at_key(key)
    root.at_key(key)
  end

  # In java this is an overloaded version of atKey
  def at_key_with_origin(origin, key)
    root.at_key_with_origin(origin, key)
  end

  def with_only_path(path_expression)
    path = Path.new_path(path_expression)
    self.class.new(root.with_only_path(path))
  end

  def without_path(path_expression)
    path = Path.new_path(path_expression)
    self.class.new(root.without_path(path))
  end

  def with_value(path_expression, v)
    path = Path.new_path(path_expression)
    self.class.new(root.with_value(path, v))
  end

  def to_fallback_value
    @object
  end

  def with_fallback(other)
    @object.with_fallback(other).to_config
  end
end
