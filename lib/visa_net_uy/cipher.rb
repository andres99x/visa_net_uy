require_relative 'encoder'
require 'openssl'

class VisaNetUy::Cipher
  include VisaNetUy::Encoder

  CIPHER_ALGORITHM = "DES-EDE3-CBC"

  # Generates a session_key
  def generate_session_key
    # Generate random session key with 16 bytes length
    OpenSSL::Random.random_bytes(16)

    return '1234567890123456'
  end

  # Encrypt data using the public_key
  def urlsafe_base64_asymmetric_encrypt(data, public_key)
    #  Load key
    pkey = OpenSSL::PKey::RSA.new(public_key, nil)
    raise 'Invalid public key.' unless pkey.public?

    # Encrypt data
    encrypted_data = pkey.public_encrypt(data)
    # Encode encrypted data with custom Encoder
    custom_base64_urlsafe_encode(encrypted_data)
  end

  # Decrypt data using the private_key
  def urlsafe_base64_asymmetric_decrypt(urlsafe_base64_encrypted_data, private_key)
    #  Load key
    pkey = OpenSSL::PKey::RSA.new(private_key, nil)
    raise 'Invalid private key.' unless pkey.private?

    # Decode encrypted data with custom decoding
    encrypted_data = custom_base64_urlsafe_decode(urlsafe_base64_encrypted_data)
    # Decrypt encrypted data
    pkey.private_decrypt(encrypted_data)
  end

  # Encrypt data with key
  def urlsafe_base64_symmetric_encrypt(data, key, iv)
    raise 'Initialization Vector must have 16 hexadecimal characters.' unless iv.length == 16
    raise 'Key must have 16 hexadecimal characters.' unless key.length == 16

    bin_iv = [iv].pack('H*')
    raise 'Initialization Vector is not valid, must contain only hexadecimal characters.' if bin_iv.empty?

    key += key.byteslice(0,8)

    # len = data.length
    # padding = BLOCK_SIZE - (len % BLOCK_SIZE)
    # data += padding.chr * padding

    cipher = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
    cipher.encrypt
    cipher.iv = bin_iv
    cipher.key = key
    # cipher.padding = 0

    encrypted_data = cipher.update(data) + cipher.final

    custom_base64_urlsafe_encode(encrypted_data)
  end

  def urlsafe_base64_symmetric_decrypt(urlsafe_base64_encrypted_data, key, iv)

    raise 'Vector must have 16 hexadecimal characters.' unless iv.length == 16
    raise 'Key must have 16 hexadecimal characters.' unless key.length == 16

    bin_iv = [iv].pack('H*')
    raise 'Initialization Vector is not valid, must contain only hexadecimal characters.' if bin_iv.empty?

    key += key.byteslice(0,8)

    cipher = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
    cipher.decrypt
    cipher.iv = bin_iv
    cipher.key = key
    # cipher.padding = 0

    encrypted_data = custom_base64_urlsafe_decode(urlsafe_base64_encrypted_data.gsub('.','='))
    data = cipher.update(encrypted_data) + cipher.final

    # packing = BLOCK_SIZE > data.last.ord ? data.last.ord : 0
    #
    # data.slice(0, data.length - packing)
  end

end
