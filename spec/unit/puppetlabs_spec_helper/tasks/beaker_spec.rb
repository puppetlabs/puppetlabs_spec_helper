require 'spec_helper'
require 'puppetlabs_spec_helper/tasks/beaker'

describe SetupBeaker do
  describe '.setup_beaker' do
    let(:task) { RSpec::Core::RakeTask.new }

    it 'can set tag for low tier' do
      allow(ENV).to receive(:[]).and_return('low')
      expect(described_class.setup_beaker(task).rspec_opts.to_s).to match(%r{--tag tier_low})
    end
    it 'can set tag for high, medium and low tier' do
      allow(ENV).to receive(:[]).and_return('high, medium, low')
      expect(described_class.setup_beaker(task).rspec_opts.to_s).to match(%r{--tag tier_high} && %r{--tag tier_medium} && %r{--tag tier_low})
    end
    it 'does not set a tag when ENV[TEST_TIERS] is nil' do
      allow(ENV).to receive(:[]).and_return(nil)
      expect(described_class.setup_beaker(task).rspec_opts.to_s).not_to match(%r{--tag})
    end
    it 'errors when tier specified does not exist' do
      allow(ENV).to receive(:[]).and_return('expect_error')
      expect { described_class.setup_beaker(task) }.to raise_error(RuntimeError, %r{not a valid test tier})
    end
    it 'errors when tiers are quoted' do
      allow(ENV).to receive(:[]).and_return('"high", "medium", "low"')
      expect { described_class.setup_beaker(task) }.to raise_error(RuntimeError, %r{not a valid test tier})
    end
  end
end
