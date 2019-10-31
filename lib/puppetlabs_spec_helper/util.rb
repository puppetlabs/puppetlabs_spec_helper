require 'puppet'

module PuppetlabsSpecHelper; end

module PuppetlabsSpecHelper::Util
  def puppet_3_or_older?
    Puppet.version.split('.').first.to_i <= 3
  end
end
