class Experian::Xml

  include Experian::Codes
  
  def initialize(xml_string)
    @xml_string = xml_string
  end

  def to_document
    REXML::Document.new(@xml_string)
  end
  
  def to_responses
    document = to_document

    {
      ADDRESS      => get_response_code(document, 'GeneralResults/AddressVerificationResult'),
      ADDRESS_TYPE => get_response_code(document, 'GeneralResults/AddressTypeResult'),
      PHONE        => get_response_code(document, 'GeneralResults/PhoneVerificationResult'),
      SSN          => get_response_code(document, 'GeneralResults/SSNResult'),
      DOB          => get_response_code(document, 'GeneralResults/DateOfBirthMatch'),
      OFAC         => get_response_code(document, 'GeneralResults/OFACResult'),
      SCORE        => get_response_code(document, 'PreciseIDScore'),
    }
  end

  def get_response_code(document, element_name)
    elements = REXML::XPath.match(document, "//#{element_name}")
    
    p "****** Found #{elements.length} node(s) for //#{element_name} ******" if elements.length > 1
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
