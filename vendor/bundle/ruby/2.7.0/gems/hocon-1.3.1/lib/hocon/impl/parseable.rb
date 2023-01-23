# encoding: utf-8

require 'stringio'
require 'pathname'
require 'hocon/impl'
require 'hocon/config_error'
require 'hocon/config_syntax'
require 'hocon/config_value_type'
require 'hocon/impl/config_impl'
require 'hocon/impl/simple_include_context'
require 'hocon/impl/simple_config_object'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/tokenizer'
require 'hocon/impl/config_parser'
require 'hocon/config_parseable'
require 'hocon/impl/config_document_parser'
require 'hocon/impl/simple_config_document'

#
# Internal implementation detail, not ABI stable, do not touch.
# For use only by the {@link com.typesafe.config} package.
# The point of this class is to avoid "propagating" each
# overload on "thing which can be parsed" through multiple
# interfaces. Most interfaces can have just one overload that
# takes a Parseable. Also it's used as an abstract "resource
# handle" in the ConfigIncluder interface.
#
class Hocon::Impl::Parseable
  include Hocon::ConfigParseable

  # Internal implementation detail, not ABI stable, do not touch
  module Relativizer
    def relative_to(filename)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Relativizer` must implement `relative_to` (#{self.class})"
    end
  end

  # The upstream library seems to use this as a global way of keeping track of
  # how many files have been included, to avoid cycles
  def self.parse_stack
    Thread.current[:hocon_parse_stack] ||= []
  end

  MAX_INCLUDE_DEPTH = 50

  def initialize

  end

  def fixup_options(base_options)
    syntax = base_options.syntax
    if !syntax
      syntax = guess_syntax
    end
    if !syntax
      syntax = Hocon::ConfigSyntax::CONF
    end
    modified = base_options.set_syntax(syntax)

    # make sure the app-provided includer falls back to default
    modified = modified.append_includer(Hocon::Impl::ConfigImpl.default_includer)
    # make sure the app-provided includer is complete
    modified = modified.set_includer(Hocon::Impl::SimpleIncluder.make_full(modified.includer))

    modified
  end

  def post_construct(base_options)
    @initial_options = fixup_options(base_options)
    @include_context = Hocon::Impl::SimpleIncludeContext.new(self)
    if @initial_options.origin_description
      @initial_origin = Hocon::Impl::SimpleConfigOrigin.new_simple(@initial_options.origin_description)
    else
      @initial_origin = create_origin
    end
  end

  # the general idea is that any work should be in here, not in the
  # constructor, so that exceptions are thrown from the public parse()
  # function and not from the creation of the Parseable.
  # Essentially this is a lazy field. The parser should close the
  # reader when it's done with it.
  #{//}# ALSO, IMPORTANT: if the file or URL is not found, this must throw.
  #{//}# to support the "allow missing" feature.
  def custom_reader
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Parseable` must implement `custom_reader` (#{self.class})"
  end

  def reader(options)
    custom_reader
  end

  def self.trace(message)
    if Hocon::Impl::ConfigImpl.trace_loads_enabled
      Hocon::Impl::ConfigImpl.trace(message)
    end
  end

  def guess_syntax
    nil
  end

  def content_type
    nil
  end

  def relative_to(filename)
    # fall back to classpath; we treat the "filename" as absolute
    # (don't add a package name in front),
    # if it starts with "/" then remove the "/", for consistency
    # with ParseableResources.relativeTo
    resource = filename
    if filename.start_with?("/")
      resource = filename.slice(1)
    end
    self.class.new_resources(resource, options.set_origin_description(nil))
  end

  def include_context
    @include_context
  end

  def self.force_parsed_to_object(value)
    if value.is_a? Hocon::Impl::AbstractConfigObject
      value
    else
      raise Hocon::ConfigError::ConfigWrongTypeError.with_expected_actual(value.origin,
                                                         "",
                                                         "object at file root",
                                                         Hocon::ConfigValueType.value_type_name(value.value_type))
    end
  end

  def parse(base_options = nil)
    if (base_options.nil?)
      base_options = options
    end
    stack = self.class.parse_stack
    if stack.length >= MAX_INCLUDE_DEPTH
      raise Hocon::ConfigError::ConfigParseError.new(@initial_origin,
            "include statements nested more than #{MAX_INCLUDE_DEPTH} times, " +
            "you probably have a cycle in your includes.  Trace: #{stack}",
            nil)
    end

    # Push into beginning of stack
    stack.unshift(self)
    begin
      self.class.force_parsed_to_object(parse_value(base_options))
    ensure
      # Pop from beginning of stack
      stack.shift
    end
  end

  def parse_value(base_options = nil)
    if base_options.nil?
      base_options = options
    end

    # note that we are NOT using our "initialOptions",
    # but using the ones from the passed-in options. The idea is that
    # callers can get our original options and then parse with different
    # ones if they want.
    options = fixup_options(base_options)

    # passed-in options can override origin
    origin =
        if options.origin_description
          Hocon::Impl::SimpleConfigOrigin.new_simple(options.origin_description)
        else
          @initial_origin
        end
    parse_value_from_origin(origin, options)
  end

  def parse_value_from_origin(origin, final_options)
    begin
      raw_parse_value(origin, final_options)
    rescue IOError => e
      if final_options.allow_missing?
        Hocon::Impl::SimpleConfigObject.empty_missing(origin)
      else
        self.class.trace("exception loading #{origin.description}: #{e.class}: #{e.message}")
        raise Hocon::ConfigError::ConfigIOError.new(origin, "#{e.class.name}: #{e.message}", e)
      end
    end
  end

  def parse_document(base_options = nil)
    if base_options.nil?
      base_options = options
    end

    # note that we are NOT using our "initialOptions",
    # but using the ones from the passed-in options. The idea is that
    # callers can get our original options and then parse with different
    # ones if they want.
    options = fixup_options(base_options)

    # passed-in option can override origin
    origin = nil
    if ! options.origin_description.nil?
      origin = Hocon::Impl::SimpleConfigOrigin.new_simple(options.origin_description)
    else
      origin = @initial_origin
    end
    parse_document_from_origin(origin, options)
  end

  def parse_document_from_origin(origin, final_options)
    begin
      raw_parse_document(origin, final_options)
    rescue IOError => e
      if final_options.allow_missing?
        Hocon::Impl::SimpleConfigDocument.new(
          Hocon::Impl::ConfigNodeObject.new([]), final_options)
      else
        self.class.trace("exception loading #{origin.description}: #{e.class}: #{e.message}")
        raise ConfigIOError.new(origin, "#{e.class.name}: #{e.message}", e)
      end
    end
  end

  # this is parseValue without post-processing the IOException or handling
  # options.getAllowMissing()
  def raw_parse_value(origin, final_options)
    reader = reader(final_options)

    # after reader() we will have loaded the Content-Type
    content_type = content_type()

    options_with_content_type = nil
    if !(content_type.nil?)
      if Hocon::Impl::ConfigImpl.trace_loads_enabled && (! final_options.get_syntax.nil?)
        self.class.trace("Overriding syntax #{final_options.get_syntax} with Content-Type which specified #{content-type}")
      end
      options_with_content_type = final_options.set_syntax(content_type)
    else
      options_with_content_type = final_options
    end

    reader.open { |io|
      raw_parse_value_from_io(io, origin, options_with_content_type)
    }
  end

  def raw_parse_value_from_io(io, origin, final_options)
    tokens = Hocon::Impl::Tokenizer.tokenize(origin, io, final_options.syntax)
    document = Hocon::Impl::ConfigDocumentParser.parse(tokens, origin, final_options)
    Hocon::Impl::ConfigParser.parse(document, origin, final_options, include_context)
  end

  def raw_parse_document(origin, final_options)
    reader = reader(final_options)
    content_type = content_type()

    options_with_content_type = nil
    if !(content_type.nil?)
      if Hocon::Impl::ConfigImpl.trace_loads_enabled && (! final_options.get_syntax.nil?)
        self.class.trace("Overriding syntax #{final_options.get_syntax} with Content-Type which specified #{content-type}")
      end
      options_with_content_type = final_options.set_syntax(content_type)
    else
      options_with_content_type = final_options
    end

    reader.open { |io|
      raw_parse_document_from_io(io, origin, options_with_content_type)
    }
  end

  def raw_parse_document_from_io(reader, origin, final_options)
    tokens = Hocon::Impl::Tokenizer.tokenize(origin, reader, final_options.syntax)
    Hocon::Impl::SimpleConfigDocument.new(
                   Hocon::Impl::ConfigDocumentParser.parse(tokens, origin, final_options),
                   final_options)
  end

  def parse_config_document
    parse_document(options)
  end

  def origin
    @initial_origin
  end

  def create_origin
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Parseable` must implement `create_origin` (#{self.class})"
  end

  def options
    @initial_options
  end

  def to_s
    self.class.name.split('::').last
  end

  def self.syntax_from_extension(name)
    if name.end_with?(".json")
      Hocon::ConfigSyntax::JSON
    elsif name.end_with?(".conf")
      Hocon::ConfigSyntax::CONF
    else
      # Skipping PROPERTIES because we can't really support that in ruby
      nil
    end
  end

  # NOTE: skipping `readerFromStream` and `doNotClose` because they don't seem relevant in Ruby

  # NOTE: skipping `relativeTo(URL, String)` because we're not supporting URLs for now
  def self.relative_to(file, filename)
    child = Pathname.new(filename)
    file = Pathname.new(file)

    if child.absolute?
      nil
    end

    parent = file.parent

    if parent.nil?
      nil
    else
      File.join(parent, filename)
    end
  end

  # this is a parseable that doesn't exist and just throws when you try to parse it
  class ParseableNotFound < Hocon::Impl::Parseable
    def initialize(what, message, options)
      super()
      @what = what
      @message = message
      post_construct(options)
    end

    def custom_reader
      raise Hocon::ConfigError::ConfigBugOrBrokenError, @message
    end

    def create_origin
      Hocon::Impl::SimpleConfigOrigin.new_simple(@what)
    end
  end

  def self.new_not_found(what_not_found, message, options)
    ParseableNotFound.new(what_not_found, message, options)
  end

  # NOTE: skipping `ParseableReader` until we know we need it (probably should
  #  have done that with `ParseableNotFound`)

  class ParseableString < Hocon::Impl::Parseable
    def initialize(string, options)
      super()
      @input = string
      post_construct(options)
    end

    def custom_reader
      if Hocon::Impl::ConfigImpl.trace_loads_enabled
        self.class.trace("Loading config from a String: #{@input}")
      end
      # we return self here, which will cause `open` to be called on us, so
      # we can provide an implementation of that.
      self
    end

    def open
      if block_given?
        StringIO.open(@input) do |f|
          yield f
        end
      else
        StringIO.open(@input)
      end
    end

    def create_origin
      Hocon::Impl::SimpleConfigOrigin.new_simple("String")
    end

    def to_s
      "#{self.class.name.split('::').last} (#{@input})"
    end
  end

  def self.new_string(string, options)
    ParseableString.new(string, options)
  end

  # NOTE: Skipping `ParseableURL` for now as we probably won't support this right away

  class ParseableFile < Hocon::Impl::Parseable
    def initialize(input, options)
      super()
      @input = input
      post_construct(options)
    end

    def custom_reader
      if Hocon::Impl::ConfigImpl.trace_loads_enabled
        self.class.trace("Loading config from a String: #{@input}")
      end
      # we return self here, which will cause `open` to be called on us, so
      # we can provide an implementation of that.
      self
    end

    def open
      begin
        if block_given?
          File.open(@input, :encoding => 'bom|utf-8') do |f|
            yield f
          end
        else
          File.open(@input, :encoding => 'bom|utf-8')
        end
      rescue Errno::ENOENT
        if @initial_options.allow_missing?
          return Hocon::Impl::SimpleConfigObject.empty
        end

        raise Hocon::ConfigError::ConfigIOError.new(nil, "File not found. No file called #{@input}")
      end
    end

    def guess_syntax
      Hocon::Impl::Parseable.syntax_from_extension(File.basename(@input))
    end

    def relative_to(filename)
      sibling = nil
      if Pathname.new(filename).absolute?
        sibling = File.new(filename)
      else
        # this may return nil
        sibling = Hocon::Impl::Parseable.relative_to(@input, filename)
      end
      if sibling.nil?
        nil
      elsif File.exists?(sibling)
        self.class.trace("#{sibling} exists, so loading it as a file")
        Hocon::Impl::Parseable.new_file(sibling, options.set_origin_description(nil))
      else
        self.class.trace("#{sibling} does not exist, so trying it as a resource")
        super(filename)
      end
    end

    def create_origin
      Hocon::Impl::SimpleConfigOrigin.new_file(@input)
    end

    def to_s
      "#{self.class.name.split('::').last} (#{@input})"
    end

  end


  def self.new_file(file_path, options)
    ParseableFile.new(file_path, options)
  end

  # NOTE: skipping `ParseableResourceURL`, we probably won't support that

  # NOTE: this is not a faithful port of the `ParseableResources` class from the
  # upstream, because at least for now we're not going to try to do anything
  # crazy like look for files on the ruby load path.  However, there is a decent
  # chunk of logic elsewhere in the codebase that is written with the assumption
  # that this class will provide the 'last resort' attempt to find a config file
  # before giving up, so we're basically port just enough to have it provide
  # that last resort behavior
  class ParseableResources < Hocon::Impl::Parseable
    include Relativizer

    def initialize(resource, options)
      super()
      @resource = resource
      post_construct(options)
    end

    def reader
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "reader() should not be called on resources"
    end

    def raw_parse_value(origin, final_options)
      # this is where the upstream code would go out and look for a file on the
      # classpath.  We're not going to do that, and instead we're just going to
      # raise the same exception that the upstream code would raise if it failed
      # to find the file.
      raise IOError, "resource not found: #{@resource}"
    end

    def guess_syntax
      Hocon::Impl::Parseable.syntax_from_extension(@resource)
    end

    def self.parent(resource)
      # the "resource" is not supposed to begin with a "/"
      # because it's supposed to be the raw resource
      # (ClassLoader#getResource), not the
      # resource "syntax" (Class#getResource)
      i = resource.rindex("/")
      if i < 0
        nil
      else
        resource.slice(0..i)
      end
    end

    def relative_to(sibling)
      if sibling.start_with?("/")
        # if it starts with "/" then don't make it relative to the
        # including resource
        Hocon::Impl::Parseable.new_resources(sibling.slice(1), options.set_origin_description(nil))
      else
        # here we want to build a new resource name and let
        # the class loader have it, rather than getting the
        # url with getResource() and relativizing to that url.
        # This is needed in case the class loader is going to
        # search a classpath.
        parent = self.class.parent(@resource)
        if parent.nil?
          Hocon::Impl::Parseable.new_resources(sibling, options.set_origin_description(nil))
        else
          Hocon::Impl::Parseable.new_resources("#{parent}/sibling", options.set_origin_description(nil))
        end
      end
    end

    def create_origin
      Hocon::Impl::SimpleConfigOrigin.new_resource(@resource)
    end

    def to_s
      "#{self.class.name.split('::').last}(#{@resource})"
    end
  end

  def self.new_resources(resource, options)
    ParseableResources.new(resource, options)
  end




  # NOTE: skipping `ParseableProperties`, we probably won't support that

end
