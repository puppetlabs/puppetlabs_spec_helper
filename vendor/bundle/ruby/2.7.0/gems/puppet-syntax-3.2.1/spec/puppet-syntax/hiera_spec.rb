require 'spec_helper'

describe PuppetSyntax::Hiera do
  let(:subject) { PuppetSyntax::Hiera.new }

  it 'should expect an array of files' do
    expect { subject.check(nil) }.to raise_error(/Expected an array of files/)
  end

  it "should return nothing from valid YAML" do
    files = fixture_hiera('hiera_good.yaml')
    res = subject.check(files)
    expect(res).to be == []
  end

  it "should return an error from invalid YAML" do
    hiera_yaml = RUBY_VERSION =~ /1.8/ ? 'hiera_bad_18.yaml' : 'hiera_bad.yaml'
    files = fixture_hiera(hiera_yaml)
    expected = /ERROR: Failed to parse #{files[0]}:/
    res = subject.check(files)
    expect(res.size).to be == 1
    expect(res.first).to match(expected)
  end

  context 'check_hiera_keys = true' do
    before(:each) {
      PuppetSyntax.check_hiera_keys = true
    }

    it "should return warnings for invalid keys" do
      hiera_yaml = 'hiera_badkey.yaml'
      examples = 5
      files = fixture_hiera(hiera_yaml)
      res = subject.check(files)
      (1..examples).each do |n|
        expect(res).to include(/::warning#{n}/)
      end
      expect(res.size).to be == examples
      expect(res[0]).to match('Key :typical:typo::warning1: Looks like a missing colon')
      expect(res[1]).to match('Key ::notsotypical::warning2: Puppet automatic lookup will not use leading \'::\'')
      expect(res[2]).to match('Key :noCamelCase::warning3: Not a valid Puppet variable name for automatic lookup')
      expect(res[3]).to match('Key :no-hyphens::warning4: Not a valid Puppet variable name for automatic lookup')
      expect(res[4]).to match('Key :picky::warning5: Puppet automatic lookup will not look up symbols')
    end

    it "should return warnings for bad eyaml values" do
      hiera_yaml = 'hiera_bad.eyaml'
      examples = 6
      files = fixture_hiera(hiera_yaml)
      res = subject.check(files)
      (1..examples).each do |n|
        expect(res).to include(/::warning#{n}/)
      end
      expect(res.size).to be == examples
      expect(res[0]).to match('Key acme::warning1 has unknown eyaml method unknown-method')
      expect(res[1]).to match('Key acme::warning2 has unterminated eyaml value')
      expect(res[2]).to match('Key acme::warning3 has unpadded or truncated base64 data')
      expect(res[3]).to match('Key acme::warning4 has corrupt base64 data')
      expect(res[4]).to match('Key acme::warning5\[\'key2\'\] has corrupt base64 data')
      expect(res[5]).to match('Key acme::warning6\[\'hash_key\'\]\[2\] has corrupt base64 data')
    end

    it "should handle empty files" do
      hiera_yaml = 'hiera_key_empty.yaml'
      files = fixture_hiera(hiera_yaml)
      res = subject.check(files)
      expect(res).to be_empty
    end

  end
end
