require 'spec_helper'
require 'pathspec/spec'

describe PathSpec::Spec do
  subject { PathSpec::Spec.new }

  it 'does not allow matching' do
    expect { subject.match 'anything' }.to raise_error(/Unimplemented/)
  end

  it { is_expected.to be_inclusive }
end
