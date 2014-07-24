require_relative 'encoder'
require 'openssl'

class VisaNetUy::Signer
  include VisaNetUy::Encoder

  DIGEST_ALGORITHM = 'SHA1'

  # Generates an urlsafe_base64_signature
  def generate_urlsafe_base64_signature(data, private_key)
    # Load Keys
    pkey = OpenSSL::PKey::RSA.new(private_key, nil)
    raise 'Invalid private key.' unless pkey.private?

    # Create Digester
    digest = OpenSSL::Digest.new(DIGEST_ALGORITHM)

    # Generate Signature
    signature = pkey.sign(digest, data)
    raise 'RSA signing unsuccessful.' unless signature

    # Encode Signature with custom Encoder
    custom_base64_urlsafe_encode(signature)
  end

  # Verifies an urlsafe_base64_signature
  def verify_urlsafe_base64_signature(data, urlsafe_base64_signature, public_key)
    # Load Key
    pkey = OpenSSL::PKey::RSA.new(public_key, nil)
    raise 'Invalid public key.' unless pkey.public?

    # Decode Signature with custom decoding
    signature = custom_base64_urlsafe_decode(urlsafe_base64_signature)

    # Create Digester
    digest = OpenSSL::Digest.new(DIGEST_ALGORITHM)

    # Vefify Signature
    pkey.public_key.verify(digest, signature, data)
  end

end
