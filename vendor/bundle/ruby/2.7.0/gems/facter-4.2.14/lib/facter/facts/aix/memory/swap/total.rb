# frozen_string_literal: true

module Facts
  module Aix
    module Memory
      module Swap
        class Total
          FACT_NAME = 'memory.swap.total'
          ALIASES = 'swapsize'

          def call_the_resolver
            fact_value = Facter::Resolvers::Aix::Memory.resolve(:swap)
            if fact_value
              fact_value = Facter::Util::Facts::UnitConverter.bytes_to_human_readable(fact_value[:total_bytes])
            end
            [Facter::ResolvedFact.new(FACT_NAME, fact_value), Facter::ResolvedFact.new(ALIASES, fact_value, :legacy)]
          end
        end
      end
    end
  end
end
