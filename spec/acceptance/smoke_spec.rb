# frozen_string_literal: true

require 'spec_helper'
require 'open3'

# some smoke tests to verify overall sanity
RSpec.describe 'rake' do
  let(:output) do
    Open3.capture2e('rake', '--rakefile', 'spec/acceptance/fixtures/Rakefile', '-T')
  end

  it { expect(output[0]).to match(/spec_prep/) }
  it { expect(output[1]).to be_success }
end
