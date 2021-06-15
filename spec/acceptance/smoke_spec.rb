# frozen_string_literal: true

require 'spec_helper'
require 'open3'

# some smoke tests to verify overall sanity
RSpec.describe 'rake' do
  before(:all) do
    @output, @status = Open3.capture2e('rake', '--rakefile', 'spec/acceptance/fixtures/Rakefile', '-T')
  end

  it { expect(@output).to match %r{spec_prep} }
  it { expect(@status).to be_success }
end
