require 'cfpropertylist' if Puppet.features.cfpropertylist?
require_relative '../../puppet/util/execution'

module Puppet::Util::Plist

  class FormatError < RuntimeError; end

  # So I don't have to prepend every method name with 'self.' Most of the
  # methods are going to be Provider methods (as opposed to methods of the
  # INSTANCE of the provider).
  class << self
    # Defines the magic number for binary plists
    #
    # @api private
    def binary_plist_magic_number
      "bplist00"
    end

    # Defines a default doctype string that should be at the top of most plist
    # files. Useful if we need to modify an invalid doctype string in memory.
    # In version 10.9 and lower of OS X the plist at
    # /System/Library/LaunchDaemons/org.ntp.ntpd.plist had an invalid doctype
    # string. This corrects for that.
    def plist_xml_doctype
      '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    end

    # Read a plist file, whether its format is XML or in Apple's "binary1"
    # format, using the CFPropertyList gem.
    def read_plist_file(file_path)
      # We can't really read the file until we know the source encoding in
      # Ruby 1.9.x, so we use the magic number to detect it.
      # NOTE: We used IO.read originally to be Ruby 1.8.x compatible.
      if read_file_with_offset(file_path, binary_plist_magic_number.length) == binary_plist_magic_number
        plist_obj = new_cfpropertylist(:file => file_path)
        return convert_cfpropertylist_to_native_types(plist_obj)
      else
        plist_data = open_file_with_args(file_path, "r:UTF-8")
        plist = parse_plist(plist_data, file_path)
        return plist if plist

        Puppet.debug "Plist #{file_path} ill-formatted, converting with plutil"
        begin
          plist = Puppet::Util::Execution.execute(['/usr/bin/plutil', '-convert', 'xml1', '-o', '-', file_path],
                                                  {:failonfail => true, :combine => true})
          return parse_plist(plist)
        rescue Puppet::ExecutionFailure => detail
          message = _("Cannot read file %{file_path}; Puppet is skipping it.") % { file_path: file_path }
          message += '\n' + _("Details: %{detail}") % { detail: detail }
          Puppet.warning(message)
        end
      end
      return nil
    end

    # Read plist text using the CFPropertyList gem.
    def parse_plist(plist_data, file_path = '')
      bad_xml_doctype = /^.*<!DOCTYPE plist PUBLIC -\/\/Apple Computer.*$/
      # Depending on where parse_plist is called from, plist_data can be either XML or binary.
      # If we get XML, make sure ruby knows it's UTF-8 so we avoid invalid byte sequence errors.
      if plist_data.include?('encoding="UTF-8"') && plist_data.encoding != Encoding::UTF_8
        plist_data.force_encoding(Encoding::UTF_8)
      end

      begin
        if plist_data =~ bad_xml_doctype
          plist_data.gsub!( bad_xml_doctype, plist_xml_doctype )
          Puppet.debug("Had to fix plist with incorrect DOCTYPE declaration: #{file_path}")
        end
      rescue ArgumentError => e
        Puppet.debug "Failed with #{e.class} on #{file_path}: #{e.inspect}"
        return nil
      end

      begin
        plist_obj = new_cfpropertylist(:data => plist_data)
      # CFPropertyList library will raise NoMethodError for invalid data
      rescue CFFormatError, NoMethodError => e
        Puppet.debug "Failed with #{e.class} on #{file_path}: #{e.inspect}"
        return nil
      end
      convert_cfpropertylist_to_native_types(plist_obj)
    end

    # Helper method to assist in reading a file. It's its own method for
    # stubbing purposes
    #
    # @api private
    #
    # @param args [String] Extra file operation mode information to use
    #   (defaults to read-only mode 'r')
    #   This is the standard mechanism Ruby uses in the IO class, and therefore
    #   encoding may be explicitly like fmode : encoding or fmode : "BOM|UTF-*"
    #   for example, a:ASCII or w+:UTF-8
    def open_file_with_args(file, args)
      File.open(file, args).read
    end

    # Helper method to assist in generating a new CFPropertyList Plist. It's
    # its own method for stubbing purposes
    #
    # @api private
    def new_cfpropertylist(plist_opts)
      CFPropertyList::List.new(plist_opts)
    end

    # Helper method to assist in converting a native CFPropertyList object to a
    # native Ruby object (hash). It's its own method for stubbing purposes
    #
    # @api private
    def convert_cfpropertylist_to_native_types(plist_obj)
      CFPropertyList.native_types(plist_obj.value)
    end

    # Helper method to convert a string into a CFProperty::Blob, which is
    # needed to properly handle binary strings
    #
    # @api private
    def string_to_blob(str)
      CFPropertyList::Blob.new(str)
    end

    # Helper method to assist in reading a file with an offset value. It's its
    # own method for stubbing purposes
    #
    # @api private
    def read_file_with_offset(file_path, offset)
      IO.read(file_path, offset)
    end

    def to_format(format)
      if format.to_sym == :xml
        CFPropertyList::List::FORMAT_XML
      elsif format.to_sym == :binary
        CFPropertyList::List::FORMAT_BINARY
      elsif format.to_sym == :plain
        CFPropertyList::List::FORMAT_PLAIN
      else
        raise FormatError.new "Unknown plist format #{format}"
      end
    end

    # This method will write a plist file using a specified format (or XML
    # by default)
    def write_plist_file(plist, file_path, format = :xml)
      begin
        plist_to_save       = CFPropertyList::List.new
        plist_to_save.value = CFPropertyList.guess(plist)
        plist_to_save.save(file_path, to_format(format), :formatted => true)
      rescue IOError => e
        Puppet.err(_("Unable to write the file %{file_path}. %{error}") % { file_path: file_path, error: e.inspect })
      end
    end

    def dump_plist(plist_data, format = :xml)
      plist_to_save       = CFPropertyList::List.new
      plist_to_save.value = CFPropertyList.guess(plist_data)
      plist_to_save.to_str(to_format(format), :formatted => true)
    end
  end
end
