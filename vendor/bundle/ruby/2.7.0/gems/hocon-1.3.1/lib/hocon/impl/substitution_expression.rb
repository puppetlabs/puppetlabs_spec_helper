require 'hocon/impl'


class Hocon::Impl::SubstitutionExpression

  def initialize(path, optional)
    @path = path
    @optional = optional
  end
  attr_reader :path, :optional

  def change_path(new_path)
    if new_path == @path
      self
    else
      Hocon::Impl::SubstitutionExpression.new(new_path, @optional)
    end
  end

  def to_s
    "${#{@optional ? "?" : ""}#{@path.render}}"
  end

  def ==(other)
    if other.is_a? Hocon::Impl::SubstitutionExpression
      other.path == @path && other.optional == @optional
    else
      false
    end
  end

  def hash
    h = 41 * (41 + @path.hash)
    h = 41 * (h + (optional ? 1 : 0))

    h
  end
end