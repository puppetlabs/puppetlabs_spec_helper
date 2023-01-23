require 'rspec-puppet/cache'
require 'rspec-puppet/adapters'
require 'rspec-puppet/raw_string'
require 'rspec-puppet/sensitive'

module RSpec::Puppet
  module Support
    include GenericMatchers

    @@cache = RSpec::Puppet::Cache.new
    @@fixture_hiera_configs = Hash.new { |h, k| h[k] = nil }

    def subject
      lambda { catalogue }
    end

    def environment
      'rp_env'
    end

    def build_code(type, manifest_opts)
      if Puppet.version.to_f >= 4.0 or Puppet[:parser] == 'future'
        [site_pp_str, pre_cond, test_manifest(type, manifest_opts), post_cond].compact.join("\n")
      else
        [import_str, pre_cond, test_manifest(type, manifest_opts), post_cond].compact.join("\n")
      end
    end

    def guess_type_from_path(path)
      case path
      when /spec\/defines/
        :define
      when /spec\/classes/
        :class
      when /spec\/functions/
        :function
      when /spec\/hosts/
        :host
      when /spec\/types/
        :type
      when /spec\/type_aliases/
        :type_alias
      when /spec\/provider/
        :provider
      when /spec\/applications/
        :application
      else
        :unknown
      end
    end

    def stub_file_consts(example)
      if example.respond_to?(:metadata)
        type = example.metadata[:type]
      else
        type = guess_type_from_path(example.example.metadata[:file_path])
      end

      munged_facts = facts_hash(nodename(type))

      pretend_platform = find_pretend_platform(munged_facts)
      RSpec::Puppet::Consts.stub_consts_for(pretend_platform) unless pretend_platform.nil?
    end

    def find_pretend_platform(test_facts)
      from_value = lambda { |value|
        value.to_s.downcase == 'windows' ? :windows : :posix
      }

      ['operatingsystem', 'osfamily'].each do |os_fact|
        return from_value.call(test_facts[os_fact]) if test_facts.key?(os_fact)
      end

      if test_facts.key?('os') && test_facts['os'].is_a?(Hash)
        ['name', 'family'].each do |os_hash_key|
          return from_value.call(test_facts['os'][os_hash_key]) if test_facts['os'].key?(os_hash_key)
        end
      end

      nil
    end


    def load_catalogue(type, exported = false, manifest_opts = {})
      with_vardir do
        node_name = nodename(type)

        hiera_config_value = self.respond_to?(:hiera_config) ? hiera_config : nil
        hiera_data_value = self.respond_to?(:hiera_data) ? hiera_data : nil

        rspec_config_values = [
            :trusted_server_facts,
            :disable_module_hiera,
            :use_fixture_spec_hiera,
            :fixture_hiera_configs,
            :fallback_to_default_hiera,
        ].map { |setting| RSpec.configuration.send(setting) }

        build_facts = facts_hash(node_name)
        catalogue = build_catalog(
          nodename: node_name,
          facts_val: build_facts,
          trusted_facts_val: trusted_facts_hash(node_name),
          hiera_config_val: hiera_config_value,
          code: build_code(type, manifest_opts),
          exported: exported,
          node_params: node_params_hash,
          trusted_external_data: trusted_external_data_hash,
          ignored_cache_params: {
            hiera_data_value: hiera_data_value,
            rspec_config_values: rspec_config_values,
          }
        )

        test_module = type == :host ? nil : class_name.split('::').first
        if type == :define
          RSpec::Puppet::Coverage.add_filter(class_name, title)
        else
          RSpec::Puppet::Coverage.add_filter(type.to_s, class_name)
        end
        RSpec::Puppet::Coverage.add_from_catalog(catalogue, test_module)

        pretend_platform = find_pretend_platform(build_facts)
        Puppet::Util::Platform.pretend_to_be(pretend_platform) unless pretend_platform.nil?

        catalogue
      end
    end

    def import_str
      import_str = ""
      adapter.modulepath.each { |d|
        if File.exists?(File.join(d, 'manifests', 'init.pp'))
          path_to_manifest = File.join([
            d,
            'manifests',
            class_name.split('::')[1..-1]
          ].flatten)
          import_str = [
            "import '#{d}/manifests/init.pp'",
            "import '#{path_to_manifest}.pp'",
            '',
          ].join("\n")
          break
        elsif File.exists?(d)
          import_str = "import '#{adapter.manifest}'\n"
          break
        end
      }

      import_str
    end

    def site_pp_str
      return '' unless (path = adapter.manifest)

      if File.file?(path)
        File.read(path)
      elsif File.directory?(path)
        # Read and concatenate all .pp files.
        Dir[File.join(path, '*.pp')].sort.map do |f|
          File.read(f)
        end.join("\n")
      else
        ''
      end
    end

    def test_manifest(type, opts = {})
      opts[:params] = params if self.respond_to?(:params)

      if type == :class
        if opts[:params].nil? || opts[:params] == {}
          "include #{class_name}"
        else
          "class { '#{class_name}': #{param_str(opts[:params])} }"
        end
      elsif type == :application
        if opts.has_key?(:params)
          "site { #{class_name} { #{sanitise_resource_title(title)}: #{param_str(opts[:params])} } }"
        else
          raise ArgumentError, "You need to provide params for an application"
        end
      elsif type == :define
        title_str = if title.is_a?(Array)
                      '[' + title.map { |r| sanitise_resource_title(r) }.join(', ') + ']'
                    else
                      sanitise_resource_title(title)
                    end
        if opts.has_key?(:params)
          "#{class_name} { #{title_str}: #{param_str(opts[:params])} }"
        else
          "#{class_name} { #{title_str}: }"
        end
      elsif type == :host
        nil
      elsif type == :type_alias
        "$test = #{str_from_value(opts[:test_value])}\nassert_type(#{self.class.top_level_description}, $test)"
      end
    end

    def sanitise_resource_title(title)
      title.include?("'") ? title.inspect : "'#{title}'"
    end

    def nodename(type)
      return node if self.respond_to?(:node)
      if [:class, :define, :function, :application].include? type
        Puppet[:certname]
      else
        class_name
      end
    end

    def class_name
      self.class.top_level_description.downcase
    end

    def pre_cond
      if self.respond_to?(:pre_condition) && !pre_condition.nil?
        if pre_condition.is_a? Array
          pre_condition.compact.join("\n")
        else
          pre_condition
        end
      else
        nil
      end
    end

    def post_cond
      if self.respond_to?(:post_condition) && !post_condition.nil?
        if post_condition.is_a? Array
          post_condition.compact.join("\n")
        else
          post_condition
        end
      else
        nil
      end
    end

    def facts_hash(node)
      base_facts = {
        'clientversion' => Puppet::PUPPETVERSION,
        'environment'   => environment.to_s,
      }

      node_facts = {
        'hostname'   => node.split('.').first,
        'fqdn'       => node,
        'domain'     => node.split('.', 2).last,
        'clientcert' => node,
        'ipaddress6' => 'FE80:0000:0000:0000:AAAA:AAAA:AAAA',
      }

      networking_facts = {
        'hostname' => node_facts['hostname'],
        'fqdn'     => node_facts['fqdn'],
        'domain'   => node_facts['domain'],
      }

      result_facts = if RSpec.configuration.default_facts.any?
                       munge_facts(RSpec.configuration.default_facts)
                     else
                       {}
                     end

      # Merge in node facts so they always exist by default, but only if they
      # haven't been defined in `RSpec.configuration.default_facts`
      result_facts.merge!(munge_facts(node_facts)) { |_key, old_val, new_val| old_val.nil? ? new_val : old_val }
      (result_facts['networking'] ||= {}).merge!(networking_facts) { |_key, old_val, new_val| old_val.nil? ? new_val : old_val }

      # Merge in `let(:facts)` facts
      result_facts.merge!(munge_facts(base_facts))
      result_facts.merge!(munge_facts(facts)) if self.respond_to?(:facts)

      # Merge node facts again on top of `let(:facts)` facts, but only if
      # a node name is given with `let(:node)`
      if respond_to?(:node) && RSpec.configuration.derive_node_facts_from_nodename
        result_facts.merge!(munge_facts(node_facts))
        (result_facts['networking'] ||= {}).merge!(networking_facts)
      end

      # Facter currently supports lower case facts.  Bug FACT-777 has been submitted to support case sensitive
      # facts.
      downcase_facts = Hash[result_facts.map { |k, v| [k.downcase, v] }]
      downcase_facts
    end

    def node_params_hash
      params = RSpec.configuration.default_node_params
      if respond_to?(:node_params)
        params.merge(node_params)
      else
        params.dup
      end
    end

    def param_str(params)
      param_str_from_hash(params)
    end

    def trusted_facts_hash(node_name)
      return {} unless Puppet::Util::Package.versioncmp(Puppet.version, '4.3.0') >= 0

      extensions = {}

      if RSpec.configuration.default_trusted_facts.any?
        extensions.merge!(munge_facts(RSpec.configuration.default_trusted_facts))
      end

      extensions.merge!(munge_facts(trusted_facts)) if self.respond_to?(:trusted_facts)
      extensions
    end

    def trusted_external_data_hash
      return {} unless Puppet::Util::Package.versioncmp(Puppet.version, '6.14.0') >= 0

      external_data = {}

      if RSpec.configuration.default_trusted_external_data.any?
        external_data.merge!(munge_facts(RSpec.configuration.default_trusted_external_data))
      end

      external_data.merge!(munge_facts(trusted_external_data)) if self.respond_to?(:trusted_external_data)
      external_data
    end

    def server_facts_hash
      server_facts = {}

      # Add our server version to the fact list
      server_facts["serverversion"] = Puppet.version.to_s

      # And then add the server name and IP
      {"servername" => "fqdn",
        "serverip" => "ipaddress"
      }.each do |var, fact|
        if value = FacterImpl.value(fact)
          server_facts[var] = value
        else
          warn "Could not retrieve fact #{fact}"
        end
      end

      if server_facts["servername"].nil?
        host = FacterImpl.value(:hostname)
        if domain = FacterImpl.value(:domain)
          server_facts["servername"] = [host, domain].join(".")
        else
          server_facts["servername"] = host
        end
      end
      server_facts
    end

    def str_from_value(value)
      case value
      when Hash
        kvs = value.collect do |k,v|
          "#{str_from_value(k)} => #{str_from_value(v)}"
        end.join(", ")
        "{ #{kvs} }"
      when Array
        vals = value.map do |v|
          str_from_value(v)
        end.join(", ")
        "[ #{vals} ]"
      when :default
        'default'  # verbatim default keyword
      when :undef
        'undef'  # verbatim undef keyword
      when Symbol
        str_from_value(value.to_s)
      else
        escape_special_chars(value.inspect)
      end
    end

    def param_str_from_hash(params_hash)
      # the param_str has special quoting rules, because the top-level keys are the Puppet
      # params, which may not be quoted
      params_hash.collect do |k,v|
        "#{k.to_s} => #{str_from_value(v)}"
      end.join(', ')
    end

    def setup_puppet
      vardir = Dir.mktmpdir
      Puppet[:vardir] = vardir

      # Enable app_management by default for Puppet versions that support it
      if Puppet::Util::Package.versioncmp(Puppet.version, '4.3.0') >= 0 && Puppet.version.to_i < 5
        Puppet[:app_management] = ENV.include?('PUPPET_NOAPP_MANAGMENT') ? false : true
      end

      adapter.modulepath.map do |d|
        Dir["#{d}/*/lib"].entries
      end.flatten.each do |lib|
        $LOAD_PATH << lib
      end

      vardir
    end

    def with_vardir
      begin
        vardir = setup_puppet
        return yield(vardir) if block_given?
      ensure
        FileUtils.rm_rf(vardir) if vardir && File.directory?(vardir)
      end
    end

    def build_catalog_without_cache(nodename, facts_val, trusted_facts_val, hiera_config_val, code, exported, node_params, *_)
      build_catalog_without_cache_v2({
        nodename: nodename,
        facts_val: facts_val,
        trusted_facts_val: trusted_facts_val,
        hiera_config_val: hiera_config_val,
        code: code,
        exported: exported,
        node_params: node_params,
        trusted_external: {},
      })
    end

    def build_catalog_without_cache_v2(
      nodename: nil,
      facts_val: nil,
      trusted_facts_val: nil,
      hiera_config_val: nil,
      code: nil,
      exported: nil,
      node_params: nil,
      trusted_external_data: nil,
      ignored_cache_params: {}
    )

      # If we're going to rebuild the catalog, we should clear the cached instance
      # of Hiera that Puppet is using.  This opens the possibility of the catalog
      # now being rebuilt against a differently configured Hiera (i.e. :hiera_config
      # set differently in one example group vs. another).
      # It would be nice if Puppet offered a public API for invalidating their
      # cached instance of Hiera, but que sera sera.  We will go directly against
      # the implementation out of absolute necessity.
      HieraPuppet.instance_variable_set('@hiera', nil) if defined? HieraPuppet

      Puppet[:code] = code

      stub_facts! facts_val

      Puppet::Type.eachtype { |type| type.defaultprovider = nil }

      node_facts = Puppet::Node::Facts.new(nodename, facts_val.dup)
      node_params = facts_val.merge(node_params)

      node_obj = Puppet::Node.new(nodename, { :parameters => node_params, :facts => node_facts })

      trusted_info = ['remote', nodename, trusted_facts_val]
      if Puppet::Util::Package.versioncmp(Puppet.version, '6.14.0') >= 0
        trusted_info.push(trusted_external_data)
      end
      if Puppet::Util::Package.versioncmp(Puppet.version, '4.3.0') >= 0
        Puppet.push_context(
          {
            :trusted_information => Puppet::Context::TrustedInformation.new(*trusted_info)
          },
          "Context for spec trusted hash"
        )

        node_obj.add_server_facts(server_facts_hash) if RSpec.configuration.trusted_server_facts
      end

      adapter.catalog(node_obj, exported)
    end

    def stub_facts!(facts)
      Puppet.settings[:autosign] = false if Puppet.settings.include? :autosign
      FacterImpl.clear
      facts.each { |k, v| FacterImpl.add(k, :weight => 999) { setcode { v } } }
    end

    def build_catalog(*args)
      @@cache.get(*args) do |*args|
        if args.length == 1 && args.first.is_a?(Hash)
          build_catalog_without_cache_v2(**args.first)
        else
          build_catalog_without_cache(*args)
        end
      end
    end

    def munge_facts(facts)
      return facts.reduce({}) do | memo, (k, v)|
        memo.tap { |m| m[k.to_s] = munge_facts(v) }
      end if facts.is_a? Hash

      return facts.reduce([]) do |memo, v|
        memo << munge_facts(v); memo
      end if facts.is_a? Array

      facts
    end

    def escape_special_chars(string)
      string.gsub(/\$/, "\\$")
    end

    def rspec_compatibility
      if RSpec::Version::STRING < '3'
        # RSpec 2 compatibility:
        alias_method :failure_message_for_should, :failure_message
        alias_method :failure_message_for_should_not, :failure_message_when_negated
      end
    end

    def fixture_spec_hiera_conf(mod)
      return @@fixture_hiera_configs[mod.name] if @@fixture_hiera_configs.key?(mod.name)

      path = Pathname.new(mod.path)
      if path.join('spec').exist?
        path.join('spec').find do |file|
          Find.prune if %w[modules work-dir].any? do |dir|
            file.relative_path_from(path).to_s.start_with?("spec/fixtures/#{dir}")
          end
          if file.basename.to_s.eql?(Puppet::Pops::Lookup::HieraConfig::CONFIG_FILE_NAME)
            return @@fixture_hiera_configs[mod.name] = file.to_s
          end
        end
      end
      @@fixture_hiera_configs[mod.name]
    end

    # Helper to return a resource/node reference, so it gets translated in params to a raw string
    # without quotes.
    #
    # @param [String] type reference type
    # @param [String] title reference title
    # @return [RSpec::Puppet::RawString] return a new RawString with the type/title populated correctly
    def ref(type, title)
      return RSpec::Puppet::RawString.new("#{type}['#{title}']")
    end

    # Helper to return value wrapped in Sensitive type.
    #
    # @param [Object] value to wrap
    # @return [RSpec::Puppet::Sensitive] a new Sensitive wrapper with the new value
    def sensitive(value)
      return RSpec::Puppet::Sensitive.new(value)
    end

    # @!attribute [r] adapter
    #   @api private
    #   @return [Class < RSpec::Puppet::Adapters::Base]
    attr_accessor :adapter
  end
end
