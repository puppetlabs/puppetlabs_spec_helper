require 'spec_helper'

describe 'puppet_url_without_modules' do
  let(:msg) { 'puppet:// URL without modules/ found' }

  context 'puppet:// url with modules' do
    let(:code) { "'puppet:///modules/foo'" }

    it 'does not detect any problems' do
      expect(problems).to have(0).problems
    end
  end

  context 'with fix disabled' do
    context 'puppet:// url without modules' do
      let(:code) { "'puppet:///foo'" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(1)
      end
    end
  end

  context 'with fix enabled' do
    before(:each) do
      PuppetLint.configuration.fix = true
    end

    after(:each) do
      PuppetLint.configuration.fix = false
    end

    context 'puppet:// url without modules' do
      let(:code) { "'puppet:///foo'" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(1)
      end

      it 'inserts modules into the path' do
        expect(manifest).to eq("'puppet:///modules/foo'")
      end
    end
  end

  context 'double string wrapped puppet:// urls' do
    let(:code) { File.read('spec/fixtures/test/manifests/url_interpolation.pp') }

    it 'detects several problems' do
      expect(problems).to have(4).problem
    end
  end
end
