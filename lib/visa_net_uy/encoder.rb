require "base64"

module VisaNetUy
  module Encoder
    # Encodes to URLSafe Base64 and replaces = with .
    def custom_base64_urlsafe_encode(data)
      Base64.urlsafe_encode64(data).gsub('=','.')
    end

    # Decodes from URLSafe Base64 and replaces . with =
    def custom_base64_urlsafe_decode(encoded_data)
      Base64.urlsafe_decode64(encoded_data.gsub('.','='))
    end
  end
end
