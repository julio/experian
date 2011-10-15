p ">>>#{File.dirname(__FILE__)}<<<"
require File.dirname(__FILE__) + '/test_helper'
require 'request'

class RequestTest < Test::Unit::TestCase
  def test_should_build_an_xml_request_from_a_user
    user = {
      :first_name => "the first name", 
      :last_name  => "the last name", 
      :address1   => "the address1", 
      :address2   => "the address2", 
      :city       => "the city"
    }
    request = Request.new(user, EXPERIAN_CONFIG["experian"])
    
    xml_request = request.to_xml
    
    document = REXML::Document.new(xml_request)
    element = REXML::XPath.first(document, "//Street")
    
    assert_not_nil xml_request.index("<Surname>the last name</Surname>")
  end
end
