lib = File.expand_path('../lib', __FILE__) # __dir__ not supported on ruby-1.9 # rubocop:disable Style/ExpandPathArguments
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet/resource_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'puppet-resource_api'
  spec.version       = Puppet::ResourceApi::VERSION
  spec.license       = 'Apache-2.0'
  spec.authors       = ['David Schmitt']
  spec.email         = ['david.schmitt@puppet.com']

  spec.summary       = 'This library provides a simple way to write new native resources for puppet.'
  spec.homepage      = 'https://github.com/puppetlabs/puppet-resource_api'

  # on out internal jenkins, there is no git, but since it is a clean machine, we don't need to worry about anything else
  spec.files         = if system('git --help > /dev/null')
                         `git ls-files -z`.split("\x0")
                       else
                         Dir.glob('**/*')
                       end.reject do |f|
                         f.match(%r{^(test|spec|features)/})
                       end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'hocon', '>= 1.0'
end
