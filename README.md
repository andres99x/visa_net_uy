# VisaNetUy

VisaNet PHP PlugIn port for ruby.

## Installation

Add this line to your application's Gemfile:

    gem 'visa_net_uy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install visa_net_uy

## Usage

Initialize PlugIn

    plugin = VisaNetUy::PlugIn.new do |p|
      p.cipher_public_key = File.read 'ALIGNET.PHP.CRYPTO.PUBLIC.txt'
      p.cipher_private_key = File.read 'MILLAVE.CIFRADO.PRIVADA.txt'
      p.signature_public_key = File.read 'ALIGNET.PHP.SIGNATURE.PUBLIC.txt'
      p.signature_private_key = File.read 'MILLAVE.TESTING.FIRMA.PRIVADA.txt'
      p.iv = '0123456789ABCDEF'
    end

Generate POST request parameters

    plugin.vpos_request_params({
      'acquirerId' => '11',
      'commerceId' => '1111',
      'purchaseOperationNumber' => "111111",
      'purchaseAmount' => '10099',
      'purchaseCurrencyCode' => '858',
      'terminalCode' => 'VBV00111'})

Get response fields from VisaNet callback

    plugin.vpos_response_fields(response)

## Contributing

1. Fork it ( https://github.com/andres99x/visa_net_uy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
