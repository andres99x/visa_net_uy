require 'net/http'

class VisaNetUy::PlugIn

  attr_accessor :cipher_public_key, :cipher_private_key, :signature_public_key, :signature_private_key, :iv

  def initialize(options = {})
    unless block_given?
      options.each do |key, value|
        send(:"#{key}=", value)
      end
    else
      yield(self)
    end
  end

  def vpos_request_params(fields)
    request_params = {}

    # Check for required fields
    fields.include?('acquirerId') ? (request_params['IDACQUIRER'] = fields['acquirerId']) : (raise "Misssing acquirerId field.")
    fields.include?('commerceId') ? (request_params['IDCOMMERCE'] = fields['commerceId']) : (raise "Misssing commerceId field.")

    # Generate XML from fields
    xml = xmler.generate(fields)

    # Generate SessionKey
    session_key = cipher.generate_session_key

    # Generate digital signature
    urlsafe_base64_signature = signer.generate_urlsafe_base64_signature(xml, signature_private_key)
    request_params['DIGITALSIGN'] = urlsafe_base64_signature

    # Cipher XML
    urlsafe_base64_encrypted_xml = cipher.urlsafe_base64_symmetric_encrypt(xml, session_key, iv)
    request_params['XMLREQ'] = urlsafe_base64_encrypted_xml

    # Cipher SessionKey
    urlsafe_base64_encrypted_session_key = cipher.urlsafe_base64_asymmetric_encrypt(session_key, cipher_public_key)
    request_params['SESSIONKEY'] = urlsafe_base64_encrypted_session_key

    request_params
  end

  def vpos_response_fields(response)
    # Check for required fields
    response.include?('SESSIONKEY') ? (session_key = response['SESSIONKEY']) : (raise "Misssing SESSIONKEY.")
    response.include?('XMLRES') ? (xmlres = response['XMLRES']) : (raise "Misssing XMLRES.")
    response.include?('DIGITALSIGN') ? (digital_sing = response['DIGITALSIGN']) : (raise "Misssing DIGITALSIGN.")

    # Decrypt Session Key
    session_key = cipher.urlsafe_base64_asymmetric_decrypt(session_key, cipher_private_key)

    # Decrypt XML
    xml = cipher.urlsafe_base64_symmetric_decrypt(xmlres, session_key, iv)

    # Verify Signature
    raise 'Invalid Signature.' unless signer.verify_urlsafe_base64_signature(xml, digital_sing, signature_public_key)

    # Parse XML
    xmler.parse(xml)
  end

  protected

  def xmler
    @xmler ||= VisaNetUy::Xmler.new
  end

  def cipher
    @cipher ||= VisaNetUy::Cipher.new
  end

  def signer
    @signer ||= VisaNetUy::Signer.new
  end

end
