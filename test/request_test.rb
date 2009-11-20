require File.dirname(__FILE__) + '/../../test_helper'

require 'experian/request'

class Experian::RequestTest < Test::Unit::TestCase
  
  def test_should_build_an_xml_request_from_a_user_active_record
    user = User.new(:address1 => "address1", :address2 => "address2", :city => "city")
    request = Experian::Request.new(user)
    
    xml_request = request.to_xml
    
    document = REXML::Document.new(xml_request)
    element = REXML::XPath.first(document, "//Street")
    # p element
  end
end
