# The AST object for the parameters inside resource expressions
#
class Puppet::Parser::AST::ResourceParam < Puppet::Parser::AST::Branch
  attr_accessor :value, :param, :add

  def initialize(argshash)
    Puppet.warn_once('deprecations', 'AST::ResourceParam', _('Use of Puppet::Parser::AST::ResourceParam is deprecated and not fully functional'))
    super(argshash)
  end

  def each
    [@param, @value].each { |child| yield child }
  end

  # Return the parameter and the value.
  def evaluate(scope)
    value = @value.safeevaluate(scope)
    return Puppet::Parser::Resource::Param.new(
      :name   => @param,
      :value  => value.nil? ? :undef : value,
      :source => scope.source, 
      :line   => self.line,
      :file   => self.file,
      :add    => self.add
    )
  end

  def to_s
    "#{@param} => #{@value}"
  end
end
