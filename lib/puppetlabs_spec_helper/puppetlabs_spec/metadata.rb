# Main module
module PuppetlabsSpec; end
# A Metadata JSON releated functions
module PuppetlabsSpec::Metadata
  # This method returns an array of dependencies from the metadata.json file
  # in the format of an array of hashes, containing 'remote' (module_name) and
  # optionally 'ref' (version) elements. If no dependencies are specified,
  # empty array is returned
  def module_dependencies_from_metadata(metadata_opts)
    metadata = module_metadata
    return [] unless metadata.key?('dependencies')

    opts = metadata_opts['opts']
    forge = if !opts.nil? && !opts['forge'].nil?
              opts['forge']
            else
              'https://forge.puppet.com/'
            end
    dependencies = []
    metadata['dependencies'].each do |dep|
      tmp = { 'remote' => dep['name'].sub('/', '-') }

      if dep.key?('version_requirement')
        tmp['ref'] = module_version_from_requirement(
          tmp['remote'], dep['version_requirement'], forge
        )
      end
      dependencies.push(tmp)
    end

    dependencies
  end

  # This method uses the module_source_directory path to read the metadata.json
  # file into a json array
  def module_metadata
    metadata_path = "#{module_source_dir}/metadata.json"
    unless File.exist?(metadata_path)
      raise "Error loading metadata.json file from #{module_source_dir}"
    end
    JSON.parse(File.read(metadata_path))
  end

  private

  # This method takes a module name and the version requirement string from the
  # metadata.json file, containing either lower bounds of version or both lower
  # and upper bounds. The function then uses the forge rest endpoint to find
  # the most recent release of the given module matching the version requirement
  def module_version_from_requirement(mod_name, vr_str, forge_api)
    require 'net/http'
    forge_api = File.join(forge_api, '')
    uri = URI.parse("#{forge_api}v3/modules/#{mod_name}")
    req = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    req.basic_auth uri.user, uri.password unless uri.user.nil? || uri.password.nil?
    response = http.request(req)
    forge_data = JSON.parse(response.body)

    vrs = version_requirements_from_string(vr_str)

    # Here we iterate the releases of the given module and pick the most recent
    # that matches to version requirement
    forge_data['releases'].each do |rel|
      return rel['version'] if vrs.all? { |vr| vr.match?('', rel['version']) }
    end

    raise "No release version found matching '#{vr_str}'"
  end

  # This method takes a version requirement string as specified in the link
  # below, with either simply a lower bound, or both lower and upper bounds and
  # returns an array of Gem::Dependency objects
  # https://docs.puppet.com/puppet/latest/modules_metadata.html
  def version_requirements_from_string(vr_str)
    ops = vr_str.scan(%r{[(<|>|=)]{1,2}}i)
    vers = vr_str.scan(%r{[(0-9|\.)]+}i)

    raise 'Invalid version requirements' if ops.count != 0 &&
                                            ops.count != vers.count

    vrs = []
    ops.each_with_index do |op, index|
      vrs.push(Gem::Dependency.new('', "#{op} #{vers[index]}"))
    end

    vrs
  end

  # This is a helper for the self-symlink entry of fixtures.yml
  def module_source_dir
    Dir.pwd
  end
end
