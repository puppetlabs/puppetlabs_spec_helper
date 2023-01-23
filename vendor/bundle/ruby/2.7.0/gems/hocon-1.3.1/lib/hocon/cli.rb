require 'optparse'
require 'hocon'
require 'hocon/version'
require 'hocon/config_render_options'
require 'hocon/config_factory'
require 'hocon/config_value_factory'
require 'hocon/parser/config_document_factory'
require 'hocon/config_error'

module Hocon::CLI
  # Aliases
  ConfigMissingError = Hocon::ConfigError::ConfigMissingError
  ConfigWrongTypeError = Hocon::ConfigError::ConfigWrongTypeError

  # List of valid subcommands
  SUBCOMMANDS = ['get', 'set', 'unset']

  # For when a path can't be found in a hocon config
  class MissingPathError < StandardError
  end

  # Parses the command line flags and argument
  # Returns a options hash with values for each option and argument
  def self.parse_args(args)
    options = {}
    opt_parser = OptionParser.new do |opts|
      subcommands = SUBCOMMANDS.join(',')
      opts.banner = "Usage: hocon [options] {#{subcommands}} PATH [VALUE]\n\n" +
          "Example usages:\n" +
          "  hocon -i settings.conf -o new_settings.conf set some.nested.value 42\n" +
          "  hocon -f settings.conf set some.nested.value 42\n" +
          "  cat settings.conf | hocon get some.nested.value\n\n" +
          "Subcommands:\n" +
          "  get PATH - Returns the value at the given path\n" +
          "  set PATH VALUE - Sets or adds the given value at the given path\n" +
          "  unset PATH - Removes the value at the given path"

      opts.separator('')
      opts.separator('Options:')

      in_file_description = 'HOCON file to read/modify. If omitted, STDIN assumed'
      opts.on('-i', '--in-file HOCON_FILE', in_file_description) do |in_file|
        options[:in_file] = in_file
      end

      out_file_description = 'File to be written to. If omitted, STDOUT assumed'
      opts.on('-o', '--out-file HOCON_FILE', out_file_description) do |out_file|
        options[:out_file] = out_file
      end

      file_description = 'File to read/write to. Equivalent to setting -i/-o to the same file'
      opts.on('-f', '--file HOCON_FILE', file_description) do |file|
        options[:file] = file
      end

      json_description = "Output values from the 'get' subcommand in json format"
      opts.on('-j', '--json', json_description) do |json|
        options[:json] = json
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Show version') do
        puts Hocon::Version::STRING
        exit
      end
    end
    # parse! returns the argument list minus all the flags it found
    remaining_args = opt_parser.parse!(args)

    # Ensure -i and -o aren't used at the same time as -f
    if (options[:in_file] || options[:out_file]) && options[:file]
      exit_with_usage_and_error(opt_parser, "--file can't be used with --in-file or --out-file")
    end

    # If --file is used, set --in/out-file to the same file
    if options[:file]
      options[:in_file] = options[:file]
      options[:out_file] = options[:file]
    end

    no_subcommand_error(opt_parser) unless remaining_args.size > 0

    # Assume the first arg is the subcommand
    subcommand = remaining_args.shift
    options[:subcommand] = subcommand

    case subcommand
      when 'set'
        subcommand_arguments_error(subcommand, opt_parser) unless remaining_args.size >= 2
        options[:path] = remaining_args.shift
        options[:new_value] = remaining_args.shift

      when 'get', 'unset'
        subcommand_arguments_error(subcommand, opt_parser) unless remaining_args.size >= 1
        options[:path] = remaining_args.shift

      else
        invalid_subcommand_error(subcommand, opt_parser)
    end

    options
  end

  # Main entry point into the script
  # Calls the appropriate subcommand and handles errors raised from the subcommands
  def self.main(opts)
    hocon_text = get_hocon_file(opts[:in_file])

    begin
      case opts[:subcommand]
        when 'get'
          puts do_get(opts, hocon_text)
        when 'set'
          print_or_write(do_set(opts, hocon_text), opts[:out_file])
        when 'unset'
          print_or_write(do_unset(opts, hocon_text), opts[:out_file])
      end

    rescue MissingPathError
      exit_with_error("Can't find the given path: '#{opts[:path]}'")
    end

    exit
  end

  # Entry point for the 'get' subcommand
  # Returns a string representation of the the value at the path given on the
  # command line
  def self.do_get(opts, hocon_text)
    config = Hocon::ConfigFactory.parse_string(hocon_text)
    unless config.has_path?(opts[:path])
      raise MissingPathError.new
    end

    value = config.get_any_ref(opts[:path])

    render_options = Hocon::ConfigRenderOptions.defaults
    # Otherwise weird comments show up in the output
    render_options.origin_comments = false
    # If json is false, the hocon format is used
    render_options.json = opts[:json]
    # Output colons between keys and values
    render_options.key_value_separator = :colon

    Hocon::ConfigValueFactory.from_any_ref(value).render(render_options)
  end

  # Entry point for the 'set' subcommand
  # Returns a string representation of the HOCON config after adding/replacing
  # the value at the given path with the given value
  def self.do_set(opts, hocon_text)
    config_doc = Hocon::Parser::ConfigDocumentFactory.parse_string(hocon_text)
    modified_config_doc = config_doc.set_value(opts[:path], opts[:new_value])

    modified_config_doc.render
  end

  # Entry point for the 'unset' subcommand
  # Returns a string representation of the HOCON config after removing the
  # value at the given path
  def self.do_unset(opts, hocon_text)
    config_doc = Hocon::Parser::ConfigDocumentFactory.parse_string(hocon_text)
    unless config_doc.has_value?(opts[:path])
      raise MissingPathError.new
    end

    modified_config_doc = config_doc.remove_value(opts[:path])

    modified_config_doc.render
  end

  # If a file is provided, return it's contents. Otherwise read from STDIN
  def self.get_hocon_file(in_file)
    if in_file
      File.read(in_file)
    else
      STDIN.read
    end
  end

  # Print an error message and exit the program
  def self.exit_with_error(message)
    STDERR.puts "Error: #{message}"
    exit(1)
  end

  # Print an error message and usage, then exit the program
  def self.exit_with_usage_and_error(opt_parser, message)
    STDERR.puts opt_parser
    exit_with_error(message)
  end

  # Exits with an error saying there aren't enough arguments found for a given
  # subcommand. Prints the usage
  def self.subcommand_arguments_error(subcommand, opt_parser)
    error_message = "Too few arguments for '#{subcommand}' subcommand"
    exit_with_usage_and_error(opt_parser, error_message)
  end

  # Exits with an error for when no subcommand is supplied on the command line.
  # Prints the usage
  def self.no_subcommand_error(opt_parser)
    error_message = "Must specify subcommand from [#{SUBCOMMANDS.join(', ')}]"
    exit_with_usage_and_error(opt_parser, error_message)
  end

  # Exits with an error for when a subcommand doesn't exist. Prints the usage
  def self.invalid_subcommand_error(subcommand, opt_parser)
    error_message = "Invalid subcommand '#{subcommand}', must be one of [#{SUBCOMMANDS.join(', ')}]"
    exit_with_usage_and_error(opt_parser, error_message)
  end

  # If out_file is not nil, write to that file. Otherwise print to STDOUT
  def self.print_or_write(string, out_file)
    if out_file
      File.open(out_file, 'w') { |file| file.write(string) }
    else
      puts string
    end
  end
end
