# Copyright (C) 2009 Thomas Bellman
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THOMAS BELLMAN BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# Except as contained in this notice, the name of Thomas Bellman shall
# not be used in advertising or otherwise to promote the sale, use or
# other dealings in this Software without prior written authorization
# from Thomas Bellman.

Puppet::Parser::Functions::newfunction(
  :sprintf, :type => :rvalue,
  :arity => -2,
  :doc => "Perform printf-style formatting of text.

  The first parameter is format string describing how the rest of the parameters should be formatted.
  See the documentation for the [`Kernel::sprintf` function](https://ruby-doc.org/core/Kernel.html)
  in Ruby for details.
  
  To use [named format](https://idiosyncratic-ruby.com/49-what-the-format.html) arguments, provide a
  hash containing the target string values as the argument to be formatted. For example:

  ```puppet
  notice sprintf(\"%<x>s : %<y>d\", { 'x' => 'value is', 'y' => 42 })
  ```

  This statement produces a notice of `value is : 42`."

) do |args|
  fmt = args[0]
  args = args[1..-1]
  begin
    return sprintf(fmt, *args)
  rescue KeyError => e
    if args.size == 1 && args[0].is_a?(Hash)
      # map the single hash argument such that all top level string keys are symbols
      # as that allows named arguments to be used in the format string.
      #
      result = {}
      args[0].each_pair { |k,v| result[k.is_a?(String) ? k.to_sym : k] = v }
      return sprintf(fmt, result)
    end
    raise e
  end
end
