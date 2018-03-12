require 'spec_helper'
require 'puppetlabs_spec_helper/tasks/beaker'

describe SetupBeaker do
  describe '.setup_beaker' do
    let(:task) {RSpec::Core::RakeTask.new}
    it 'can set tag for low tier' do
      allow(ENV).to receive(:[]).and_return('low')
      expect(SetupBeaker.setup_beaker(task).rspec_opts.to_s).to match(/--tag tier_low/)
    end
    it 'can set tag for high, medium and low tier' do
      allow(ENV).to receive(:[]).and_return('high, medium, low')
      expect(SetupBeaker.setup_beaker(task).rspec_opts.to_s).to match(/--tag tier_high/ && /--tag tier_medium/ && /--tag tier_low/)
    end
    it 'does not set a tag when ENV[TEST_TIERS] is nil' do
      allow(ENV).to receive(:[]).and_return(nil)
      expect(SetupBeaker.setup_beaker(task).rspec_opts.to_s).to_not match(/--tag/)
    end
    it 'errors when tier specified does not exist' do
      allow(ENV).to receive(:[]).and_return('expect_error')
      expect{SetupBeaker.setup_beaker(task)}.to raise_error(RuntimeError, /not a valid test tier/)
    end
    it 'errors when tiers are quoted' do
      allow(ENV).to receive(:[]).and_return('"high", "medium", "low"')
      expect{SetupBeaker.setup_beaker(task)}.to raise_error(RuntimeError, /not a valid test tier/)
    end
  end
end
