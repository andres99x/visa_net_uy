require "rexml/document"

class VisaNetUy::Xmler
  include REXML

  VERSION = '1.0'
  Encoding = 'ISO-8859-1'
  ROOT_NAME = 'VPOSTransaction1.2'

  def generate(fields)
    fields_temp = {}
    taxes_name = {}
    taxes_amount = {}

    dom = Document.new
    dom << XMLDecl.new(VERSION, Encoding)

    root = Element.new(ROOT_NAME)
    dom << root

    fields.each_pair do |field, value|
      p field
      if VisaNetUy::VALID_FIELDS.include? field
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
      element = Element.new(field)
      element.text = value

      root << element
    end

    unless taxes_name.empty?
      taxes_root = Element.new('taxes')
      root << taxes_root

      taxes_name.each_pair do |tax, value|
        element = Element.new('Tax', nil, attribute_quote: :quote)
        element.add_attribute 'name', value
        element.add_attribute 'amount', taxes_amount[tax]

        taxes_root << element
      end
    end

    xml = ''
    dom.write(xml)

    return xml
  end

  def parse(xml)
    fields = {}

    dom = Document.new(xml)
    root = dom.root

    return fields unless root.name == ROOT_NAME

    root.elements.each do |child|

      if child.name == 'taxes'
        tax_count = 1

        child.elements.each do |tax|
          fields["tax_#{tax_count}_name"] = tax.attribute('name').value
          fields["tax_#{tax_count}_amount"] = tax.attribute('amount').value

          tax_count += 1
        end
      else
        fields[child.name] = child.get_text
      end

    end

    fields
  end

end


# Monkey Patching
module REXML
  class XMLDecl

    # Add carriage return after XMlDecl
    def write(writer, indent=-1, transitive=false, ie_hack=false)
      return nil unless @writethis or writer.kind_of? Output
      writer << START.sub(/\\/u, '')
      writer << " #{content encoding}"
      writer << STOP.sub(/\\/u, '')
      writer << "\n"
    end

    private
      # Force to use double-quotation as attribute delimiter and downcase encoding name
      def content(enc)
        rv = "version=\"#@version\""
        rv << " encoding=\"#{enc.downcase}\"" if @writeencoding || enc !~ /\Autf-8\z/i
        rv << " standalone=\"#@standalone\"" if @standalone
        rv
      end

  end
end
