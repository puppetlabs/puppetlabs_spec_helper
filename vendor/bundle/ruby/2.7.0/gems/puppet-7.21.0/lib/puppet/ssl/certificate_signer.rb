# Take care of signing a certificate in a FIPS 140-2 compliant manner.
#
# @see https://projects.puppetlabs.com/issues/17295
#
# @api private
class Puppet::SSL::CertificateSigner

  # @!attribute [r] digest
  #   @return [OpenSSL::Digest]
  attr_reader :digest

  def initialize
    if OpenSSL::Digest.const_defined?('SHA256')
      @digest = OpenSSL::Digest::SHA256
    elsif OpenSSL::Digest.const_defined?('SHA1')
      @digest = OpenSSL::Digest::SHA1
    elsif OpenSSL::Digest.const_defined?('SHA512')
      @digest = OpenSSL::Digest::SHA512
    elsif OpenSSL::Digest.const_defined?('SHA384')
      @digest = OpenSSL::Digest::SHA384
    elsif OpenSSL::Digest.const_defined?('SHA224')
      @digest = OpenSSL::Digest::SHA224
    else
      raise Puppet::Error,
        "No FIPS 140-2 compliant digest algorithm in OpenSSL::Digest"
    end
    @digest
  end

  # Sign a certificate signing request (CSR) with a private key.
  #
  # @param [OpenSSL::X509::Request] content The CSR to sign
  # @param [OpenSSL::X509::PKey] key The private key to sign with
  #
  # @api private
  def sign(content, key)
    content.sign(key, @digest.new)
  end
end
