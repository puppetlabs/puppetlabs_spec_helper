require 'puppet/gettext/config'
require 'spec_helper'

describe Puppet::GettextConfig do
  require 'puppet_spec/files'
  include PuppetSpec::Files
  include Puppet::GettextConfig

  let(:local_path) do
    local_path ||= Puppet::GettextConfig::LOCAL_PATH
  end

  let(:windows_path) do
    windows_path ||= Puppet::GettextConfig::WINDOWS_PATH
  end

  let(:posix_path) do
    windows_path ||= Puppet::GettextConfig::POSIX_PATH
  end

  before(:each) do
    allow(Puppet::GettextConfig).to receive(:gettext_loaded?).and_return(true)
  end

  after(:each) do
    Puppet::GettextConfig.set_locale('en')
    Puppet::GettextConfig.delete_all_text_domains
  end

  # These tests assume gettext is enabled, but it will be disabled when the
  # first time the `Puppet[:disable_i18n]` setting is resolved
  around(:each) do |example|
    disabled = Puppet::GettextConfig.instance_variable_get(:@gettext_disabled)
    Puppet::GettextConfig.instance_variable_set(:@gettext_disabled, false)
    begin
      example.run
    ensure
      Puppet::GettextConfig.instance_variable_set(:@gettext_disabled, disabled)
    end
  end

  describe 'setting and getting the locale' do
    it 'should return "en" when gettext is unavailable' do
      allow(Puppet::GettextConfig).to receive(:gettext_loaded?).and_return(false)

      expect(Puppet::GettextConfig.current_locale).to eq('en')
    end

    it 'should allow the locale to be set' do
      Puppet::GettextConfig.set_locale('hu')
      expect(Puppet::GettextConfig.current_locale).to eq('hu')
    end
  end

  describe 'translation mode selection' do
    it 'should select PO mode when given a local config path' do
      expect(Puppet::GettextConfig.translation_mode(local_path)).to eq(:po)
    end

    it 'should select PO mode when given a non-package config path' do
      expect(Puppet::GettextConfig.translation_mode('../fake/path')).to eq(:po)
    end

    it 'should select MO mode when given a Windows package config path' do
      expect(Puppet::GettextConfig.translation_mode(windows_path)).to eq(:mo)
    end

    it 'should select MO mode when given a POSIX package config path' do
      expect(Puppet::GettextConfig.translation_mode(posix_path)).to eq(:mo)
    end
  end

  describe 'loading translations' do
    context 'when given a nil locale path' do
      it 'should return false' do
        expect(Puppet::GettextConfig.load_translations('puppet', nil, :po)).to be false
      end
    end

    context 'when given a valid locale file location' do
      it 'should return true' do
        expect(Puppet::GettextConfig).to receive(:add_repository_to_domain).with('puppet', local_path, :po, anything)

        expect(Puppet::GettextConfig.load_translations('puppet', local_path, :po)).to be true
      end
    end

    context 'when given a bad file format' do
      it 'should raise an exception' do
        expect { Puppet::GettextConfig.load_translations('puppet', local_path, :bad_format) }.to raise_error(Puppet::Error)
      end
    end
  end

  describe "setting up text domains" do
    it 'can create the default text domain after another is set' do
      Puppet::GettextConfig.delete_all_text_domains
      FastGettext.text_domain = 'other'
      Puppet::GettextConfig.create_default_text_domain
    end

    it 'should add puppet translations to the default text domain' do
      expect(Puppet::GettextConfig).to receive(:load_translations).with('puppet', local_path, :po, Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN).and_return(true)

      Puppet::GettextConfig.create_default_text_domain
      expect(Puppet::GettextConfig.loaded_text_domains).to include(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN)
    end

    it 'should copy default translations when creating a non-default text domain' do
      Puppet::GettextConfig.reset_text_domain(:test)
      expect(Puppet::GettextConfig.loaded_text_domains).to include(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN, :test)
    end

    it 'should normalize domain name when creating a non-default text domain' do
      Puppet::GettextConfig.reset_text_domain('test')
      expect(Puppet::GettextConfig.loaded_text_domains).to include(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN, :test)
    end
  end

  describe "clearing the configured text domain" do
    it 'succeeds' do
      Puppet::GettextConfig.clear_text_domain
      expect(FastGettext.text_domain).to eq(FastGettext.default_text_domain)
    end

    it 'falls back to default' do
      Puppet::GettextConfig.reset_text_domain(:test)
      expect(FastGettext.text_domain).to eq(:test)
      Puppet::GettextConfig.clear_text_domain
      expect(FastGettext.text_domain).to eq(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN)
    end
  end

  describe "deleting text domains" do
    it 'can delete a text domain by name' do
      Puppet::GettextConfig.reset_text_domain(:test)
      expect(Puppet::GettextConfig.loaded_text_domains).to include(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN, :test)
      Puppet::GettextConfig.delete_text_domain(:test)
      expect(Puppet::GettextConfig.loaded_text_domains).to eq([Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN])
    end

    it 'can delete all non-default text domains' do
      Puppet::GettextConfig.reset_text_domain(:test)
      expect(Puppet::GettextConfig.loaded_text_domains).to include(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN, :test)
      Puppet::GettextConfig.delete_environment_text_domains
      expect(Puppet::GettextConfig.loaded_text_domains).to eq([Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN])
    end

    it 'can delete all text domains' do
      Puppet::GettextConfig.reset_text_domain(:test)
      expect(Puppet::GettextConfig.loaded_text_domains).to include(Puppet::GettextConfig::DEFAULT_TEXT_DOMAIN, :test)
      Puppet::GettextConfig.delete_all_text_domains
      expect(Puppet::GettextConfig.loaded_text_domains).to be_empty
    end
  end
end
