require 'semantic_puppet/dependency'

module SemanticPuppet
  module Dependency
    class UnsatisfiableGraph < StandardError
      attr_reader :graph, :unsatisfied

      def initialize(graph, unsatisfied = nil)
        @graph = graph

        deps = sentence_from_list(graph.modules)

        if unsatisfied
          @unsatisfied = unsatisfied
          super "Could not find satisfying releases of #{unsatisfied} for #{deps}"
        else
          super "Could not find satisfying releases for #{deps}"
        end
      end

      private

      def sentence_from_list(list)
        case list.length
        when 1
          list.first
        when 2
          list.join(' and ')
        else
          list = list.dup
          list.push("and #{list.pop}")
          list.join(', ')
        end
      end
    end
  end
end
