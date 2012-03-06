require 'net/http'
require 'hashie'

module WmsResource

  class << self

    attr_accessor :base_url
  end
end

require 'wms_resource/base'
require 'wms_resource/branding'
require 'wms_resource/listing'
