require 'rexml/document'

class Xml
  def initialize(xml_string)
    @xml_string = xml_string
  end

  def to_document
    @document ||= REXML::Document.new(@xml_string)
  end
  
  def to_responses
    {
      Codes::ADDRESS      => get_response_code(to_document, 'GeneralResults/AddressVerificationResult'),
      Codes::ADDRESS_TYPE => get_response_code(to_document, 'GeneralResults/AddressTypeResult'),
      Codes::PHONE        => get_response_code(to_document, 'GeneralResults/PhoneVerificationResult'),
      Codes::SSN          => get_response_code(to_document, 'GeneralResults/SSNResult'),
      Codes::DOB          => get_response_code(to_document, 'GeneralResults/DateOfBirthMatch'),
      Codes::OFAC         => get_response_code(to_document, 'GeneralResults/OFACResult'),
      Codes::SCORE        => get_response_code(to_document, 'PreciseIDScore'),
    }
  end

  def get_response_code(document, element_name)
    elements = REXML::XPath.match(document, "//#{element_name}")
    
    element = elements[0]
    
    result = ''
    if element
      if element.attributes['code']
        result = element.attributes['code']
      else
        result = element.text
      end
      result.strip! if result
    end
    result
    
  end
end
