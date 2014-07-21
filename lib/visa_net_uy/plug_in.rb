require "rexml/document"
require 'openssl'
require "base64"

class VisaNetUy::PlugIn
  include REXML

  BLOCK_SIZE = 8

  def generate_xml(fields = {})
    fields_temp = {}
    taxes_name = {}
    taxes_amount = {}

    dom = Document.new
    dom << XMLDecl.new('1.0', 'iso-8859-1')

    root = Element.new('VPOSTransaction1.2')
    dom << root

    fields.each_pair do |field, value|

      if VisaNet::VALID_FIELDS.include? field
        fields_temp[field] = value
      elsif !field.scan(/tax_\d{1,2}_name/).empty?
        taxes_name[field.gsub(/(^tax_)|(_name$)/,'')] = value
      elsif !field.scan(/tax_\d{1,2}_amount/).empty?
        taxes_amount[field.gsub(/(^tax_)|(_amount$)/,'')] = value
      else
        raise "#{field} is not a valid field."
      end

    end

    fields_temp.each_pair do |field, value|
      element = Element.new field
      element.text = value

      root << element
    end


    unless taxes_name.empty?
      taxes_root = Element.new('taxes')
      root << taxes_root

      taxes_name.each_pair do |tax, value|
        element = Element.new('Tax')
        element.add_attribute 'name', value
        element.add_attribute 'amount', taxes_amount[tax]

        taxes_root << element
      end
    end

    dom.to_s
  end

  def parse_xml(xml = nil)
    fieds = {}

    dom = Document.new(xml)
    root = dom.root

    return fields unless root.attribute('name') == 'VPOSTransaction1.2'

    root.elements.each do |child|

      if child.attributes('name') == 'taxes'
        tax_count = 1

        child.elements.each do |tax|
          fields["tax_#{tax_count}_name"] = tax.attributes('name')
          fields["tax_#{tax_count}_amount"] = tax.attributes('amount')

          tax_count += 1
        end
      else
        fields[child.attributes('name')] = child.get_text
      end

    end

    return fields

  end

  def vpos_send(fields, cipher_public_key, signature_private_key, vi)

    # Generate XML from fields
    xml = generate_xml(fields)

    # Generate digital signature
    urlsafe_base64_signature = generate_urlsafe_base64_signature(xml, signature_private_key)

    # Generate SessionKey
    session_key = generate_session_key

    # Cipher XML
    urlsafe_base64_encrypted_xml = urlsafe_base64_symmetric_encrypt(xml, session_key, vi)

    # Cipher SessionKey
    urlsafe_base64_encrypted_session_key = urlsafe_base64_encrypt(session_key, cipher_public_key)

    return { 'SESSIONKEY' => urlsafe_base64_encrypted_session_key,
             'XMLREQ' => urlsafe_base64_encrypted_xml,
             'DIGITALSIGN' => urlsafe_base64_signature}
  end

  def vpos_response (fields, signature_public_key, cipher_private_key, vi)

    raise 'Missing fields.' unless fields.include?('SESSIONKEY') && fields.include?('XMLRES') && fields.include?('DIGITALSIGN')

    session_key = urlsafe_base64_decrypt(fields['SESSIONKEY'], cipher_private_key)

    xml = urlsafe_base64_symmetric_decrypt(fields['XMLRES'], session_key, vi)

    return false unless verify_urlsafe_base64_signature(xml, fields['DIGITALSIGN'], signature_public_key)

    parse_xml(xml)

  end

  def generate_urlsafe_base64_signature(data, private_key)

    openssl_rsa = OpenSSL::PKey::RSA.new(private_key, nil)

    raise 'Invalid private key.' unless openssl_rsa.private?

    digest = OpenSSL::Digest::SHA1.new
    signature = openssl_rsa.sign(digest, data)

    raise 'RSA signing unsuccessful.' unless signature

    Base64.urlsafe_encode64(encrypted_data)

  end

  def verify_urlsafe_base64_signature(data, signature, public_key)

    openssl_rsa = OpenSSL::PKey::RSA.new(public_key, nil)

    raise 'Invalid public key.' unless openssl_rsa.public?

    digest = OpenSSL::Digest::SHA1.new

    openssl_rsa.public_key.verify(digest, Base64.urlsafe_decode64(signature), data)

  end

  def generate_session_key

    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.encrypt
    cipher.random_iv

  end

  def urlsafe_base64_encrypt(data, public_key)

    openssl_rsa = OpenSSL::PKey::RSA.new(public_key, nil)

    raise 'Invalid public key.' unless openssl_rsa.public?

    encrypted_data = openssl_rsa.public_encrypt(data)

    Base64.urlsafe_encode64(encrypted_data)

  end

  def urlsafe_base64_decrypt(encrypted_data, private_key)

    openssl_rsa = OpenSSL::PKey::RSA.new(private_key, nil)

    raise 'Invalid private key.' unless openssl_rsa.private?

    data = openssl_rsa.private_decrypt(Base64.urlsafe_decode64(encrypted_data))

  end

  def urlsafe_base64_symmetric_encrypt(data, key, vector)

    raise 'Vector must have 16 hexadecimal characters.' unless vector.length == 16
    raise 'Key must have 16 hexadecimal characters.' unless key.length == 16

    bin_vector = [vector].pack('H*')
    raise 'Initialization Vector is not valid, must contain only hexadecimal characters.' if bin_vector.blank?

    key += key.byteslice(0,8)

    len = data.length
    padding = BLOCK_SIZE - (len % BLOCK_SIZE)
    data += padding.chr * padding

    cipher = OpenSSL::Cipher::Cipher.new("des-ede3-cbc")
    cipher.encrypt
    cipher.vi = bin_vector
    cipher.key = key
    cipher.padding = 0

    encrypted_data = cipher.update(data) + cipher.final

    Base64.urlsafe_encode64(encrypted_data)

  end

  def urlsafe_base64_symmetric_decrypt(encrypted_data, key, vector)

    raise 'Vector must have 16 hexadecimal characters.' unless vector.length == 16
    raise 'Key must have 16 hexadecimal characters.' unless key.length == 16

    bin_vector = [vector].pack('H*')
    raise 'Initialization Vector is not valid, must contain only hexadecimal characters.' if bin_vector.blank?

    key += key.byteslice(0,8)

    cipher = OpenSSL::Cipher::Cipher.new("des-ede3-cbc")
    cipher.decrypt
    cipher.vi = bin_vector
    cipher.key = key
    cipher.padding = 0

    decrypted_data = cipher.update(Base64.urlsafe_decode64(encrypted_data)) + cipher.final

    packing = BLOCK_SIZE > decrypted_data.last.ord ? decrypted_data.last.ord : 0

    decrypted_data.slice(0, decrypted_data.length - packing)

  end

end
