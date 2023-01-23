# Calls a [lambda](https://puppet.com/docs/puppet/latest/lang_lambdas.html)
# without arguments if the value given to `lest` is `undef`.
# Returns the result of calling the lambda if the argument is `undef`, otherwise the
# given argument.
#
# The `lest` function is useful in a chain of `then` calls, or in general
# as a guard against `undef` values. The function can be used to call `fail`, or to
# return a default value.
#
# These two expressions are equivalent:
#
# ```puppet
# if $x == undef { do_things() }
# lest($x) || { do_things() }
# ```
#
# @example Using the `lest` function
#
# ```puppet
# $data = {a => [ b, c ] }
# notice $data.dig(a, b, c)
#  .then |$x| { $x * 2 }
#  .lest || { fail("no value for $data[a][b][c]" }
# ```
#
# Would fail the operation because `$data[a][b][c]` results in `undef`
# (there is no `b` key in `a`).
#
# In contrast - this example:
#
# ```puppet
# $data = {a => { b => { c => 10 } } }
# notice $data.dig(a, b, c)
#  .then |$x| { $x * 2 }
#  .lest || { fail("no value for $data[a][b][c]" }
# ```
#
# Would notice the value `20`
#
# @since 4.5.0
#
Puppet::Functions.create_function(:lest) do
  dispatch :lest do
    param 'Any', :arg
    block_param 'Callable[0,0]', :block
  end

  def lest(arg)
    if arg.nil?
      yield()
    else
      arg
    end
  end
end
