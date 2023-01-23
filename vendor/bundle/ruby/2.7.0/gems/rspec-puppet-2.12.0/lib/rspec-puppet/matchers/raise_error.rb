module RSpec::Puppet
  module GenericMatchers
    # Due to significant code base depending on the
    #
    #     is_expected.to raise_error Puppet::Error
    #
    # syntax, and removal of this syntax from RSpec, extend RSpec's built-in
    # `raise_error` matcher to accept a value target, e.g. a subject defined
    # as a lambda, e.g.:
    #
    #     subject(:catalogue) { lambda { load_catalogue } }
    #
    class RaiseError < RSpec::Matchers::BuiltIn::RaiseError
      def supports_value_expectations?
        true
      end
    end

    def raise_error(error=defined?(RSpec::Matchers::BuiltIn::RaiseError::UndefinedValue) ? RSpec::Matchers::BuiltIn::RaiseError::UndefinedValue : nil, message=nil, &block)
      RaiseError.new(error, message, &block)
    end
  end
end
