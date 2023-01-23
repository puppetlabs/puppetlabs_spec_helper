require 'erb'
require 'puppet'
require 'stringio'

module PuppetSyntax
  class Templates
    def check(filelist)
      raise "Expected an array of files" unless filelist.is_a?(Array)

      # We now have to redirect STDERR in order to capture warnings.
      $stderr = warnings = StringIO.new()
      result = { warnings: [], errors: [] }

      filelist.each do |file|
        if File.extname(file) == '.epp' or PuppetSyntax.epp_only
          tmp = validate_epp(file)
        elsif File.extname(file) == '.erb'
          tmp = validate_erb(file)
        end
        result.merge!(tmp) { |k, a, b| a.concat(b) } unless tmp.nil?
      end

      $stderr = STDERR
      result[:warnings] << warnings.string unless warnings.string.empty?

      result[:errors].map! { |e| e.to_s }
      result[:warnings].map! { |w| w.to_s }

      result
    end

    def validate_epp(filename)
      require 'puppet/pops'
      result = { warnings: [], errors: [] }
      formatter = Puppet::Pops::Validation::DiagnosticFormatterPuppetStyle.new
      evaluating_parser = Puppet::Pops::Parser::EvaluatingParser::EvaluatingEppParser.new()
      parser = evaluating_parser.parser()
      begin
        parse_result = parser.parse_file(filename)
        validation_result = evaluating_parser.validate(parse_result.model)

        # print out any warnings
        validation_result.warnings.each do |warn|
          message = formatter.format_message(warn)
          file = warn.file
          line = warn.source_pos.line
          column = warn.source_pos.pos
          result[:warnings] << "#{file}:#{line}:#{column}: #{message}"
        end

        # collect errors and return them in order to indicate validation failure
        validation_result.errors.each do |err|
          message = formatter.format_message(err)
          file = err.file
          line = err.source_pos.line
          column = err.source_pos.pos
          result[:errors] << "#{file}:#{line}:#{column}: #{message}"
        end
      rescue Puppet::ParseError, SyntaxError => exc
        result[:errors] << exc
      rescue => exc
        result[:errors] << exc
      end

      result
    end

    def validate_erb(filename)
      result = { warnings: [], errors: [] }

      begin
        template = File.read(filename)
        erb = if RUBY_VERSION >= '2.6'
                ERB.new(template, trim_mode: '-')
              else
                ERB.new(template, nil, '-')
              end
        erb.filename = filename
        erb.result
      rescue NameError => error
        # This is normal because we don't have the variables that would
        # ordinarily be bound by the parent Puppet manifest.
      rescue TypeError
        # This is normal because we don't have the variables that would
        # ordinarily be bound by the parent Puppet manifest.
      rescue SyntaxError => error
        result[:errors] << error
      end

      result
    end
  end
end
