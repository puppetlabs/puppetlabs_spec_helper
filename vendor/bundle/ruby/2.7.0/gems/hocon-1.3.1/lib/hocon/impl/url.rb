# encoding: utf-8

require 'uri'
require 'hocon/impl'

# There are several places in the Java codebase that
# use Java's URL constructor, and rely on it to throw
# a `MalformedURLException` if the URL isn't valid.
#
# Ruby doesn't really have a similar constructor /
# validator, so this is a little shim to hopefully
# make the ported code match up with the upstream more
# closely.
class Hocon::Impl::Url
  class MalformedUrlError < StandardError
    def initialize(msg, cause = nil)
      super(msg)
      @cause = cause
    end
  end

  def initialize(url)
    begin
      # URI::parse wants a string
      @url = URI.parse(url.to_s)
      if !(@url.kind_of?(URI::HTTP))
        raise MalformedUrlError, "Unrecognized URL: '#{url}'"
      end
    rescue URI::InvalidURIError => e
      raise MalformedUrlError.new("Unrecognized URL: '#{url}' (error: #{e})", e)
    end
  end

  def to_s
    @url.to_s
  end
end
