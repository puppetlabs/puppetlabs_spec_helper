require 'spec_helper'

require 'puppet/ssl/certificate_request_attributes'

describe Puppet::SSL::CertificateRequestAttributes do
  include PuppetSpec::Files

  let(:expected) do
    {
      "custom_attributes" => {
        "1.3.6.1.4.1.34380.2.2"=>[3232235521, 3232235777], # system IPs in hex
        "1.3.6.1.4.1.34380.2.0"=>"hostname.domain.com",
        "1.3.6.1.4.1.34380.1.1.3"=>:node_image_name,
        # different UTF-8 widths
        # 1-byte A
        # 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
        # 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
        # 4-byte 𠜎 - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
        "1.2.840.113549.1.9.7"=>"utf8passwordA\u06FF\u16A0\u{2070E}"
      }
    }
  end
  let(:csr_attributes_hash) { expected.dup }
  let(:csr_attributes_path) { tmpfile('csr_attributes.yaml') }
  let(:csr_attributes) { Puppet::SSL::CertificateRequestAttributes.new(csr_attributes_path) }

  it "initializes with a path" do
    expect(csr_attributes.path).to eq(csr_attributes_path)
  end

  describe "loading" do
    it "returns nil when loading from a non-existent file" do
      nonexistent = Puppet::SSL::CertificateRequestAttributes.new('/does/not/exist.yaml')
      expect(nonexistent.load).to be_falsey
    end

    context "with an available attributes file" do
      before do
        Puppet::Util::Yaml.dump(csr_attributes_hash, csr_attributes_path)
      end

      it "loads csr attributes from a file when the file is present" do
        expect(csr_attributes.load).to be_truthy
      end

      it "exposes custom_attributes" do
        csr_attributes.load
        expect(csr_attributes.custom_attributes).to eq(expected['custom_attributes'])
      end

      it "returns an empty hash if custom_attributes points to nil" do
        Puppet::Util::Yaml.dump({'custom_attributes' => nil }, csr_attributes_path)
        csr_attributes.load
        expect(csr_attributes.custom_attributes).to eq({})
      end

      it "returns an empty hash if custom_attributes key is not present" do
        Puppet::Util::Yaml.dump({}, csr_attributes_path)
        csr_attributes.load
        expect(csr_attributes.custom_attributes).to eq({})
      end

      it "raises a Puppet::Error if an unexpected root key is defined" do
        csr_attributes_hash['unintentional'] = 'data'
        Puppet::Util::Yaml.dump(csr_attributes_hash, csr_attributes_path)
        expect {
          csr_attributes.load
        }.to raise_error(Puppet::Error, /unexpected attributes.*unintentional/)
      end

      it "raises a Puppet::Util::Yaml::YamlLoadError if an unexpected ruby object is present" do
        csr_attributes_hash['custom_attributes']['whoops'] = Object.new
        Puppet::Util::Yaml.dump(csr_attributes_hash, csr_attributes_path)
        expect {
          csr_attributes.load
        }.to raise_error(Puppet::Util::Yaml::YamlLoadError, /Tried to load unspecified class: Object/)
      end
    end
  end
end
