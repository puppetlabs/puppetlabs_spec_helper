require 'spec_helper'

describe PuppetSyntax::Templates do
  let(:subject) { PuppetSyntax::Templates.new }
  let(:conditional_warning_regex) do
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6.0')
      %r{2: warning: found `= literal' in conditional}
    else
      %r{2: warning: found = in conditional}
    end
  end

  it 'should expect an array of files' do
    expect { subject.check(nil) }.to raise_error(/Expected an array of files/)
  end

  it 'should return nothing from a valid file' do
    files = fixture_templates('pass.erb')
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should ignore NameErrors from unbound variables' do
    files = fixture_templates('pass_unbound_var.erb')
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should catch SyntaxError' do
    files = fixture_templates('fail_error.erb')
    res = subject.check(files)

    expect(res[:errors].size).to eq(1)
    expect(res[:errors][0]).to match(/2: syntax error, unexpected/)
  end

  it 'should catch Ruby warnings' do
    files = fixture_templates('fail_warning.erb')
    res = subject.check(files)

    expect(res[:warnings].size).to eq(1)
    expect(res[:warnings][0]).to match(conditional_warning_regex)
  end

  it 'should read more than one valid file' do
    files = fixture_templates(['pass.erb', 'pass_unbound_var.erb'])
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should continue after finding an error in the first file' do
    files = fixture_templates(['fail_error.erb', 'fail_warning.erb'])
    res = subject.check(files)

    expect(res[:warnings].size).to eq(1)
    expect(res[:errors].size).to eq(1)
    expect(res[:errors][0]).to match(/2: syntax error, unexpected/)
    expect(res[:warnings][0]).to match(conditional_warning_regex)
  end

  it 'should ignore a TypeError' do
    files = fixture_templates('typeerror_shouldwin.erb')
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should ignore files without .erb extension' do
    files = fixture_templates('ignore.tpl')
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should return nothing from a valid file' do
    files = fixture_templates('pass.epp')
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should catch SyntaxError' do
    files = fixture_templates('fail_error.epp')
    res = subject.check(files)

    expect(res[:errors].size).to eq(1)
    expect(res[:errors][0]).to match(/This Type-Name has no effect/)
  end

  it 'should read more than one valid file' do
    files = fixture_templates(['pass.epp', 'pass_also.epp'])
    res = subject.check(files)

    expect(res[:warnings]).to match([])
    expect(res[:errors]).to match([])
  end

  it 'should continue after finding an error in the first file' do
    files = fixture_templates(['fail_error.epp', 'fail_error_also.epp'])
    res = subject.check(files)

    expect(res[:errors].size).to eq(2)
    expect(res[:errors][0]).to match(/This Type-Name has no effect/)
    expect(res[:errors][1]).to match(/Syntax error at '}' \(file: \S*\/fail_error_also.epp, line: 2, column: 4\)/)
  end

  context "when the 'epp_only' options is set" do
    before(:each) {
      PuppetSyntax.epp_only = true
    }

    it 'should process an ERB as EPP and find an error' do
      files = fixture_templates('pass.erb')
      res = subject.check(files)

      expect(res[:errors].size).to eq(1)
    end
  end
end
