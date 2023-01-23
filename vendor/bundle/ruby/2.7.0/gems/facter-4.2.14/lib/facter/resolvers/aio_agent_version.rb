# frozen_string_literal: true

module Facter
  module Resolvers
    class AioAgentVersion < BaseResolver
      init_resolver

      class << self
        private

        def post_resolve(fact_name, _options)
          @fact_list.fetch(fact_name) { read_agent_version }
        end

        def read_agent_version
          aio_agent_version = Facter::Util::FileHelper.safe_read('/opt/puppetlabs/puppet/VERSION', nil)&.chomp
          aio_agent_version = aio_agent_version&.match(/^\d+\.\d+\.\d+(\.\d+){0,2}/)&.to_s
          @fact_list[:aio_agent_version] = aio_agent_version
        end
      end
    end
  end
end
