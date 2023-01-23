# frozen_string_literal: true

module Facts
  module Solaris
    class Interfaces
      FACT_NAME = 'interfaces'
      TYPE = :legacy

      def call_the_resolver
        fact_value = Facter::Resolvers::Solaris::Networking.resolve(:interfaces)

        Facter::ResolvedFact.new(FACT_NAME, fact_value && !fact_value.empty? ? fact_value.keys.sort.join(',') : nil,
                                 :legacy)
      end
    end
  end
end
