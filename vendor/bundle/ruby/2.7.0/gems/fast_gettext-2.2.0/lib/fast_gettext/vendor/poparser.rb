# -*- coding: utf-8 -*-
#
# poparser.rb - Generate a .mo
#
# Copyright (C) 2003-2009 Masao Mutoh <mutomasa at gmail.com>
# Copyright (C) 2012 Kouhei Sutou <kou@clear-code.com>
#
# You may redistribute it and/or modify it under the same
# license terms as Ruby or LGPL.

#MODIFIED
# removed include GetText
# added stub translation method _(message_id)

require 'racc/parser.rb'
module FastGettext
module GetText
  class PoParser < Racc::Parser

  module_eval(<<'...end poparser.ry/module_eval...', 'poparser.ry', 118)

  def _(message_id)
    message_id
  end
  private :_

  attr_writer :ignore_fuzzy, :report_warning
  def initialize
    @ignore_fuzzy = true
    @report_warning = true
  end

  def ignore_fuzzy?
    @ignore_fuzzy
  end

  def report_warning?
    @report_warning
  end

  def unescape(orig)
    ret = orig.gsub(/\\n/, "\n")
    ret.gsub!(/\\t/, "\t")
    ret.gsub!(/\\r/, "\r")
    ret.gsub!(/\\"/, "\"")
    ret
  end
  private :unescape

  def unescape_string(string)
    string.gsub(/\\\\/, "\\")
  end
  private :unescape_string

  def parse(str, data)
    @comments = []
    @data = data
    @fuzzy = false
    @msgctxt = ""

    str.strip!
    @q = []
    until str.empty? do
      case str
      when /\A\s+/
	str = $'
      when /\Amsgctxt/
	@q.push [:MSGCTXT, $&]
	str = $'
      when /\Amsgid_plural/
	@q.push [:MSGID_PLURAL, $&]
	str = $'
      when /\Amsgid/
	@q.push [:MSGID, $&]
	str = $'
      when /\Amsgstr/
	@q.push [:MSGSTR, $&]
	str = $'
      when /\A\[(\d+)\]/
	@q.push [:PLURAL_NUM, $1]
	str = $'
      when /\A\#~(.*)/
        if report_warning?
          $stderr.print _("Warning: obsolete msgid exists.\n")
          $stderr.print "         #{$&}\n"
        end
	@q.push [:COMMENT, $&]
	str = $'
      when /\A\#(.*)/
	@q.push [:COMMENT, $&]
	str = $'
      when /\A\"(.*)\"/
	@q.push [:STRING, unescape_string($1)]
	str = $'
      else
	#c = str[0,1]
	#@q.push [:STRING, c]
	str = str[1..-1]
      end
    end
    @q.push [false, '$end']
    if $DEBUG
      @q.each do |a,b|
      puts "[#{a}, #{b}]"
      end
    end
    @yydebug = true if $DEBUG
    do_parse

    if @comments.size > 0
      @data.set_comment(:last, @comments.join("\n"))
    end
    @data
  end

  def next_token
    @q.shift
  end

  def on_message(msgid, msgstr)
    if msgstr.size > 0
      @data[msgid] = msgstr
      @data.set_comment(msgid, @comments.join("\n"))
    end
    @comments.clear
    @msgctxt = ""
  end

  def on_comment(comment)
    @fuzzy = true if (/fuzzy/ =~ comment)
    @comments << comment
  end

  def parse_file(po_file, data)
    @po_file = po_file
    encoding = detect_file_encoding(po_file)
    parse(File.open(po_file, "r:#{encoding}") {|io| io.read }, data)
  end

  def detect_file_encoding(po_file)
    open(po_file, :encoding => 'ASCII-8BIT') do |input|
      input.each_line do |line|
        return Encoding.find($1) if %r["Content-Type:.*\scharset=(.*)\\n"] =~ line
      end
    end
    Encoding.default_external
  end
  private :detect_file_encoding
...end poparser.ry/module_eval...
##### State transition tables begin ###

    racc_action_table = [
      2,    13,    10,     9,     6,    17,    16,    15,    22,    15,
        15,    13,    13,    13,    15,    11,    22,    24,    13,    15 ]

    racc_action_check = [
      1,    17,     1,     1,     1,    14,    14,    14,    19,    19,
        12,     6,    16,     9,    18,     2,    20,    22,    24,    25 ]

    racc_action_pointer = [
      nil,     0,    15,   nil,   nil,   nil,     4,   nil,   nil,     6,
        nil,   nil,     3,   nil,     0,   nil,     5,    -6,     7,     2,
        10,   nil,     9,   nil,    11,    12 ]

    racc_action_default = [
      -1,   -16,   -16,    -2,    -3,    -4,   -16,    -6,    -7,   -16,
        -13,    26,    -5,   -15,   -16,   -14,   -16,   -16,    -8,   -16,
        -9,   -11,   -16,   -10,   -16,   -12 ]

    racc_goto_table = [
      12,    21,    23,    14,     4,     5,     3,     7,     8,    20,
        18,    19,     1,   nil,   nil,   nil,   nil,   nil,    25 ]

    racc_goto_check = [
      5,     9,     9,     5,     3,     4,     2,     6,     7,     8,
        5,     5,     1,   nil,   nil,   nil,   nil,   nil,     5 ]

    racc_goto_pointer = [
      nil,    12,     5,     3,     4,    -6,     6,     7,   -10,   -18 ]

    racc_goto_default = [
      nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil ]

    racc_reduce_table = [
      0, 0, :racc_error,
        0, 10, :_reduce_none,
        2, 10, :_reduce_none,
        2, 10, :_reduce_none,
        2, 10, :_reduce_none,
        2, 12, :_reduce_5,
        1, 13, :_reduce_none,
        1, 13, :_reduce_none,
        4, 15, :_reduce_8,
        5, 16, :_reduce_9,
        2, 17, :_reduce_10,
        1, 17, :_reduce_none,
        3, 18, :_reduce_12,
        1, 11, :_reduce_13,
        2, 14, :_reduce_14,
        1, 14, :_reduce_15 ]

    racc_reduce_n = 16

    racc_shift_n = 26

    racc_token_table = {
      false => 0,
      :error => 1,
      :COMMENT => 2,
      :MSGID => 3,
      :MSGCTXT => 4,
      :MSGID_PLURAL => 5,
      :MSGSTR => 6,
      :STRING => 7,
      :PLURAL_NUM => 8 }

    racc_nt_base = 9

    racc_use_result_var = true

    Racc_arg = [
      racc_action_table,
        racc_action_check,
        racc_action_default,
        racc_action_pointer,
        racc_goto_table,
        racc_goto_check,
        racc_goto_default,
        racc_goto_pointer,
        racc_nt_base,
        racc_reduce_table,
        racc_token_table,
        racc_shift_n,
        racc_reduce_n,
        racc_use_result_var ]

    Racc_token_to_s_table = [
      "$end",
        "error",
        "COMMENT",
        "MSGID",
        "MSGCTXT",
        "MSGID_PLURAL",
        "MSGSTR",
        "STRING",
        "PLURAL_NUM",
        "$start",
        "msgfmt",
        "comment",
        "msgctxt",
        "message",
        "string_list",
        "single_message",
        "plural_message",
        "msgstr_plural",
        "msgstr_plural_line" ]

    Racc_debug_parser = true

##### State transition tables end #####

# reduce 0 omitted

# reduce 1 omitted

# reduce 2 omitted

# reduce 3 omitted

# reduce 4 omitted

    module_eval(<<'.,.,', 'poparser.ry', 25)
  def _reduce_5(val, _values, result)
        @msgctxt = unescape(val[1]) + "\004"

    result
  end
.,.,

# reduce 6 omitted

# reduce 7 omitted

    module_eval(<<'.,.,', 'poparser.ry', 37)
  def _reduce_8(val, _values, result)
        msgid_raw = val[1]
    msgid = unescape(msgid_raw)
    msgstr = unescape(val[3])
    use_message_p = true
    if @fuzzy and not msgid.empty?
      use_message_p = (not ignore_fuzzy?)
      if report_warning?
        if ignore_fuzzy?
          $stderr.print _("Warning: fuzzy message was ignored.\n")
        else
          $stderr.print _("Warning: fuzzy message was used.\n")
        end
        $stderr.print "  #{@po_file}: msgid '#{msgid_raw}'\n"
      end
    end
    @fuzzy = false
    on_message(@msgctxt + msgid, msgstr) if use_message_p
    result = ""
    result
  end
.,.,

    module_eval(<<'.,.,', 'poparser.ry', 60)
  def _reduce_9(val, _values, result)
        if @fuzzy and ignore_fuzzy?
      if val[1] != ""
        if report_warning?
          $stderr.print _("Warning: fuzzy message was ignored.\n")
          $stderr.print "msgid = '#{val[1]}\n"
        end
      else
        on_message('', unescape(val[3]))
      end
      @fuzzy = false
    else
      on_message(@msgctxt + unescape(val[1]) + "\000" + unescape(val[3]), unescape(val[4]))
    end
    result = ""

    result
  end
.,.,

    module_eval(<<'.,.,', 'poparser.ry', 80)
  def _reduce_10(val, _values, result)
        if val[0].size > 0
      result = val[0] + "\000" + val[1]
    else
      result = ""
    end

    result
  end
.,.,

# reduce 11 omitted

    module_eval(<<'.,.,', 'poparser.ry', 92)
  def _reduce_12(val, _values, result)
        result = val[2]

    result
  end
.,.,

    module_eval(<<'.,.,', 'poparser.ry', 99)
  def _reduce_13(val, _values, result)
        on_comment(val[0])

    result
  end
.,.,

    module_eval(<<'.,.,', 'poparser.ry', 107)
  def _reduce_14(val, _values, result)
        result = val.delete_if{|item| item == ""}.join

    result
  end
.,.,

    module_eval(<<'.,.,', 'poparser.ry', 111)
  def _reduce_15(val, _values, result)
        result = val[0]

    result
  end
.,.,

    def _reduce_none(val, _values, result)
      val[0]
    end

  end   # class PoParser
end   # module GetText
end
