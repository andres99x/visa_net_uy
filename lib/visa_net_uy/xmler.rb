require "rexml/document"

# Monkey Patching
module REXML
  class XMLDecl

    private
      # Force to use double-quotation as attribute delimiter and downcase encoding name for XMLDecl
      def content(enc)
        rv = "version=\"#@version\""
        rv << " encoding=\"#{enc.downcase}\"" if @writeencoding || enc !~ /\Autf-8\z/i
        rv << " standalone=\"#@standalone\"" if @standalone
        rv
      end

  end
end

class VisaNetUy::Xmler
  include REXML

  VERSION = '1.0'
  Encoding = 'ISO-8859-1'
  ROOT_NAME = 'VPOSTransaction1.2'

  def generate(fields)
    fields_temp = {}

    dom = Document.new
    dom << XMLDecl.new(VERSION, Encoding)

    root = Element.new(ROOT_NAME)
    dom << root

    fields.each_pair do |field, value|
      if VisaNetUy::VALID_FIELDS.include? field
        fields_temp[field] = value
      else
        raise "#{field} is not a valid field."
      end
    end

    fields_temp.each_pair do |field, value|
      element = Element.new(field)
      element.text = value

      root << element
    end

    xml = ''
    dom.write(xml)

    xml
  end

  def parse(xml)
    fields = {}

    dom = Document.new(xml)
    root = dom.root

    return fields unless root.name == ROOT_NAME

    root.elements.each do |child|
      fields[child.name] = child.get_text.nil? ? child.get_text : child.get_text.value
    end

    fields
  end

end
