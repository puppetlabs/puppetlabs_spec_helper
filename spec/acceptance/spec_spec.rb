require 'spec_helper'
require 'open3'

# some smoke tests to verify overall sanity
RSpec.describe 'Testing rake tasks for final acceptance' do
  def rake(task)
    Dir.chdir('spec/acceptance/fixtures') do
      @output, @status = Open3.capture2e(
        'rake', task
      )
    end
  end

  describe 'rake -T' do
    before(:all) { rake '-T' }

    it { expect(@output).to match %r{beaker} }
    it { expect(@output).to match %r{spec_prep} }
    it { expect(@status).to be_success }
  end

  describe 'rake spec' do
    before(:all) { rake 'spec' }

    it { expect(@status).to be_success }
    it { expect(@output).to match %r{inkblot-bind} }
    it { expect(@output).to match %r{puppetlabs-apache} }
    it { expect(@output).to match %r{puppetlabs-mysql} }
  end
end
