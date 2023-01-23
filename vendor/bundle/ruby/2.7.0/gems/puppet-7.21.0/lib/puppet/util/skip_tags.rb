require_relative '../../puppet/util/tagging'

class Puppet::Util::SkipTags
  include Puppet::Util::Tagging

  def initialize(stags)
    self.tags = stags unless defined?(@tags)
  end

  def split_qualified_tags?
    false
  end
end
