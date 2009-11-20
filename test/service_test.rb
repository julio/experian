# require File.dirname(__FILE__) + '/../../test_helper'

require 'experian/xml'
require 'experian_result'

class ExperianTest < Test::Unit::TestCase
  include Exceptions
  include Experian::Codes

  fixtures :experian_results
  fixtures :users
  
  def setup
    @url                 = CONFIG["experian"]["path"]
    @host                = CONFIG["experian"]["host"]
    @experian_connection = EXPERIAN[:disabled]
  end
  
  def teardown
    CONFIG["experian"]["host"]     = @host
    CONFIG["experian"]["path"]     = @url
    EXPERIAN[:disabled] = @experian_connection
  end

  def test_should_log_failed_experian_check_in_console
    output = StringIO.new
    
    Experian::Service.any_instance.stubs(:logger).returns(Logger.new(output))
    
    responses = {:one => "1", :two => "2"}
    
    Experian::Service.new(User.first).log_failed_experian_check_in_console(
      User.first, Experian::Validator.new(responses), responses)
    assert_not_nil output.string.index("one => 1")
  end
  
  def test_should_log_bad_responses
    output = StringIO.new
    
    Experian::Service.any_instance.stubs(:logger).returns(Logger.new(output))
    
    Experian::Service.new(User.first).log_response(MockXmlResponse.new("foo"))
    assert_not_nil output.string.index("stuff => ")
  end
  
  def test_should_store_the_raw_xml_response_no_matter_what
    ExperianResult.delete_all
    assert_equal 0, ExperianResult.count
    
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    Experian::Validator.any_instance.stubs(:match?).returns(true)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})
  
    EXPERIAN[:disabled] = false
    
    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user

    assert_equal 1, ExperianResult.count
    assert_equal "some xml", ExperianResult.find(:first).xml_response
  end
  
  def test_should_update_account_status_to_good_after_failing_when_fixed
    responses = {ADDRESS => "X", PHONE => "X", DOB => "6", SSN => "X", SCORE => "600"}
    validator = Experian::Validator.new(responses)
    user = User.new
    
    validator.stubs(:on_ofac?).returns(true)
    validator.stubs(:good_score?).returns(false)
    experian_service = Experian::Service.new(user)
    experian_service.update_user_status(user, validator)
    assert_equal StatusCodes::USER_PENDING_OFAC_AND_CS, user.account_status
    
    validator.stubs(:on_ofac?).returns(false)
    validator.stubs(:good_score?).returns(true)
    experian_service = Experian::Service.new(user)
    experian_service.update_user_status(user, validator)
    assert_equal StatusCodes::USER_ACTIVE, user.account_status
  end
  
  def test_should_accept_users_with_low_scores
    EXPERIAN[:validate_responses] = true

    user = User.new(
      :first_name     => "Lorna",
      :last_name      => "Rodriguez-Medina",
      :ssn            => "896810987",
      :phone          => "9035452514",
      :address1       => "2510 JO LYN LN",
      :city           => "ARLINGTON",
      :state_province => "TX",
      :postal_code    => "76014",
      :dob            => Date.new(1933,1,1))
      
    experian = Experian::Service.new(user)
    responses = {ADDRESS => "X", PHONE => "X", DOB => "6", SSN => "X", SCORE => "600"}
    validator = Experian::Validator.new(responses)
    code = experian.process_experian_result(user, validator, responses, "xml")
    assert_equal Experian::Codes::EXPERIAN_ALLOWED, code
  end

  def test_should_return_MATCH_if_experian_connection_is_none
    EXPERIAN[:disabled] = true

    fraudulent_user = User.new(
      :first_name     => "Lorna",
      :last_name      => "Rodriguez-Medina",
      :ssn            => "896810987",
      :phone          => "9035452514",
      :address1       => "2510 JO LYN LN",
      :city           => "ARLINGTON",
      :state_province => "TX",
      :postal_code    => "76014",
      :dob            => Date.new(1933,1,1))
      
    experian = Experian::Service.new(fraudulent_user)
    responses = {ADDRESS => "Y", PHONE => "S", DOB => "1", SSN => "NI", SCORE => "600"} # NI is bad...mkay
    validator = Experian::Validator.new(responses)
    code = experian.process_experian_result(fraudulent_user, validator, responses, "xml")
    assert_equal Experian::Codes::EXPERIAN_ALLOWED, code
  end
  
  def test_should_raise_exception_if_we_get_bogus_url_to_post_to
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("http://www.cfexperian.com/something/servlet"))
    
    assert_raise InvalidExperianUrl do
      experian = Experian::Service.new(nil)
      experian.get_post_url
    end
  end

  def test_should_send_requests_to_experian_by_verifying_certificate
    user = User.new
    service = Experian::Service.new(user)
  
    EXPERIAN[:accept_responses] = true
    EXPERIAN[:verify_certificate] = true

    xml = Experian::Request.new(user).to_xml

    # Raises SSL Error as the verisign pem file is invalid and is verify
    assert_raise OpenSSL::SSL::SSLError do
      service.send_request(xml, service.get_post_url)
    end
  end

  def test_should_send_requests_to_experian
    user = User.new
    service = Experian::Service.new(user)
  
    EXPERIAN[:accept_responses] = true

    xml = Experian::Request.new(user).to_xml
    response = service.send_request(xml, service.get_post_url)

    # sucks having to do this, but experian is not very reliable, and we don't 
    # want our tests to break because of them. we have other tests that 
    # test experian without actually talking to them, so we're covered there
    if response.code != '200'
      # response.each {|k,v| p "#{k} => #{v}"}
      failure("Cannot connect to Experian. Response code is '#{response.code}'. Check if password has expired.")
      failure("Redirecting to '#{response['location']}'. Maybe we got locked out?") if response.code == '302'
    else
      success(".")
    end
  end
  
  def test_should_raise_exception_when_we_experian_connection_fails
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Net::HTTP.any_instance.stubs(:request).raises("exception")
  
    user = User.new
    service = Experian::Service.new(user)
  
    xml = Experian::Request.new(user).to_xml
    http = Net::HTTP.new(CONFIG["experian"]["host"], CONFIG["experian"]["path"])
    begin
      response = service.send_request(http, xml)
      flunk "should have raised exception"
    rescue
      # good
    end
  end
  
  def test_should_validate_good_xml_responses
    user = User.new
    service = Experian::Service.new(user)
    response = Net::HTTP.get_response('mysite.com', '/index.html')
    assert service.valid_xml_response?(response)
  end
  
  def test_should_invalidate_bad_xml_responses
    user = User.new
    service = Experian::Service.new(user)
    assert !service.valid_xml_response?("")
  end
  
  def test_should_respond_it_cannot_connect_if_get_post_url_raises_exception
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:get_post_url).raises("exception")
  
    EXPERIAN[:disabled] = false

    user = User.new
    service = Experian::Service.new(user)
    assert_equal EXPERIAN_CANNOT_CONNECT, service.check_user
  end

  def test_should_respond_it_cannot_connect_on_bad_xml_response
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(false)
  
    EXPERIAN[:disabled] = false
    
    user = User.new
    service = Experian::Service.new(user)
    assert_equal EXPERIAN_CANNOT_CONNECT, service.check_user
  end

  def test_should_log_warnings_if_no_match
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    Experian::Validator.any_instance.stubs(:match?).returns(false)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})
  
    EXPERIAN[:disabled] = false

    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
    assert_equal "some xml", user.experian_check_result, "the xml response should be stored in the database"
  end

  def test_should_store_the_xml_response_if_match
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    Experian::Validator.any_instance.stubs(:match?).returns(true)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})
  
    EXPERIAN[:disabled] = false
    
    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
    assert_equal "some xml", user.experian_check_result, "the xml response should be stored in the database"
  end

  def test_should_return_cannot_connect_flag_if_exception_while_getting_response_from_experian
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).raises("exception")
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    Experian::Validator.any_instance.stubs(:match?).returns(true)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})
  
    EXPERIAN[:disabled] = false
    
    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
    assert_equal Experian::Codes::EXPERIAN_CANNOT_CONNECT, code
  end
  
  def test_should_store_the_xml_response_if_no_match
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    Experian::Validator.any_instance.stubs(:match?).returns(false)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})
  
    EXPERIAN[:disabled] = false

    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
    assert_equal "some xml", user.experian_check_result, "the xml response should be stored in the database"
  end
  
  def test_should_not_store_the_xml_response_if_there_isnt_one_when_we_could_not_connect
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(false)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
  
    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
    assert_nil user.experian_check_result, "there should be no xml response to store in the database"
  end
  
  def test_should_set_user_to_pending_when_ofac_raises_alert
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(true)
    Experian::Validator.any_instance.stubs(:match?).returns(true)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})
  
    EXPERIAN[:disabled] = false
    EXPERIAN[:validate_responses]  = true

    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
  
    assert_equal StatusCodes::USER_PENDING_OFAC_AND_CS, user.account_status, "unexpected account status after failing ofac"
  end
  
  def test_should_leave_new_user_as_active_when_ofac_passes
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    Experian::Validator.any_instance.stubs(:match?).returns(true)
    Experian::Validator.any_instance.stubs(:good_score?).returns(true)
    Experian::Xml.any_instance.stubs(:to_responses).returns({})

    EXPERIAN[:disabled] = true
  
    user = User.new
    service = Experian::Service.new(user)
    code = service.check_user
    assert_equal Experian::Codes::EXPERIAN_ALLOWED, code # not really interesting, since we're mocking this, but just to make sure
  
    assert_equal StatusCodes::USER_ACTIVE, user.account_status, "unexpected account status after passing ofac"
  end
  
  def test_should_raise_exception_when_experian_service_get_response_raises_an_exception
    user = User.new
    service = Experian::Service.new(user)
  
    xml = Experian::Request.new(user).to_xml
    begin
      response = service.get_response(MockHttp.new, xml)
      flunk "should have raised exception"
    rescue
      # good
    end
  end

  def test_should_connect_if_valid_certificate
    
    CONFIG["experian"]["host"] = "www.experian.com"
    CONFIG["experian"]["path"] = "/lookupServlet1?lookupServiceName=AccessPoint&lookupServiceVersion=1.0&serviceName=NetConnect&serviceVersion=0.1&responseType=text/plain" # bad url but good certificate
    
    user = User.new(
      :first_name     => "Lorna",
      :last_name      => "Rodriguez-Medina",
      :ssn            => "897781853",
      :phone          => "9035452514",
      :address1       => "2510 JO LYN LN",
      :city           => "ARLINGTON",
      :state_province => "TX",
      :postal_code    => "76014",
      :dob            => Date.new(1933,1,1))
  
    assert_nothing_raised do
      experian = Experian::Service.new(user)
      experian.check_user
    end
  end

  def test_should_validate_good_url
    assert_nothing_raised do
      experian = Experian::Service.new(nil)
      url = experian.get_post_url
      assert_not_nil url
    end
  end
  
  def _test_should_match_a_good_user_according_to_experian
    user = User.new(
      :first_name     => "Lorna",
      :last_name      => "Rodriguez-Medina",
      :ssn            => "897781853",
      :phone          => "9035452514",
      :address1       => "2510 JO LYN LN",
      :city           => "ARLINGTON",
      :state_province => "TX",
      :postal_code    => "76014",
      :dob            => Date.new(1933,1,1))
      
    experian = Experian::Service.new(user)
    assert_equal Experian::Codes::EXPERIAN_ALLOWED, experian.check_user, "\nExperian user mismatch - maybe the experian server is down?\n"
  end

  def test_should_not_match_a_bad_user_according_to_experian
    Net::HTTP.any_instance.stubs(:get).returns(MockXmlResponse.new("https://www.experian.com/something"))
    Experian::Service.any_instance.stubs(:valid_xml_response?).returns(true)
    Experian::Service.any_instance.stubs(:send_request).returns(MockXmlResponse.new)
    Experian::Service.any_instance.stubs(:process_experian_result).returns(Experian::Codes::EXPERIAN_FRAUD)
    
    user = User.new(
      :first_name     => "Lorna",
      :last_name      => "Rodriguez-Medina",
      :ssn            => "896810987", # fraud SSN (NI: Not Issued)
      :phone          => "9035452514",
      :address1       => "2510 JO LYN LN",
      :city           => "ARLINGTON",
      :state_province => "TX",
      :postal_code    => "76014",
      :dob            => Date.new(1933,1,1))
      
    EXPERIAN[:disabled] = false

    experian = Experian::Service.new(user)
    assert_equal Experian::Codes::EXPERIAN_FRAUD, experian.check_user, "Experian user data should not be a match"
  end

  # FIXME - Experian throws a 500 when we hit their server. They know about it (well, I emailed them about it)
  #         and hopefully we will be able to fix this test when they fix their server
  def FIXME_test_should_raise_exception_if_we_get_bogus_certificate_in_api_response
    CONFIG["experian"]["host"] = "www.experian.com"
    CONFIG["experian"]["path"] = "/lookupServlet1?lookupServiceName=AccessPoint&lookupServiceVersion=1.0&serviceName=NetConnect&serviceVersion=0.2&responseType=text/plain"
    EXPERIAN[:accept_responses] = true
    
    user = User.new(
      :first_name     => "Lorna",
      :last_name      => "Rodriguez-Medina",
      :ssn            => "897781853",
      :phone          => "9035452514",
      :address1       => "2510 JO LYN LN",
      :city           => "ARLINGTON",
      :state_province => "TX",
      :postal_code    => "76014",
      :dob            => Date.new(1933,1,1))

    assert_raise InvalidExperianUrl do
      experian = Experian::Service.new(user)
      experian.check_user
    end
  end
  
  def test_should_set_user_status_based_on_ofac_and_match_score
    user = User.new
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    responses = {ADDRESS => "Y", PHONE => "X", DOB => "X", SSN => "X", SCORE => "0"} # score is only 1
    validator = Experian::Validator.new(responses)
    service = Experian::Service.new(user)
    service.update_user_status(user, validator)
    assert_equal StatusCodes::USER_PENDING_CS, user.account_status

    user = User.new
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(false)
    responses = {ADDRESS => "Y", PHONE => "X", DOB => "1", SSN => "X", SCORE => "0"} # score is 2 (good)
    validator = Experian::Validator.new(responses)
    service = Experian::Service.new(user)
    service.update_user_status(user, validator)
    assert_equal StatusCodes::USER_ACTIVE, user.account_status

    user = User.new
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(true)
    responses = {ADDRESS => "Y", PHONE => "X", DOB => "X", SSN => "X", SCORE => "0"} # score is only 1
    validator = Experian::Validator.new(responses)
    service = Experian::Service.new(user)
    service.update_user_status(user, validator)
    assert_equal StatusCodes::USER_PENDING_OFAC_AND_CS, user.account_status

    user = User.new
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(true)
    responses = {ADDRESS => "Y", PHONE => "X", DOB => "1", SSN => "X", SCORE => "0"} # score is 2
    validator = Experian::Validator.new(responses)
    service = Experian::Service.new(user)
    service.update_user_status(user, validator)
    assert_equal StatusCodes::USER_PENDING_OFAC, user.account_status

    user = User.new
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(true)
    responses = {ADDRESS => "Y", PHONE => "X", DOB => "1", SSN => "X", SCORE => "1000"}
    validator = Experian::Validator.new(responses)
    service = Experian::Service.new(user)
    service.update_user_status(user, validator)
    assert validator.match_score >= MINIMUM_GOOD_SCORE
    assert_equal StatusCodes::USER_PENDING_OFAC_AND_CS, user.account_status

    user = User.new
    Experian::Validator.any_instance.stubs(:on_ofac?).returns(true)
    responses = {ADDRESS => "Y", PHONE => "X", DOB => "1", SSN => "X", SCORE => "999"}
    validator = Experian::Validator.new(responses)
    service = Experian::Service.new(user)
    service.update_user_status(user, validator)
    assert validator.match_score >= MINIMUM_GOOD_SCORE
    assert_equal StatusCodes::USER_PENDING_OFAC, user.account_status
  end
end

class MockXmlResponse
  def initialize(body="some xml")
    @body = body
  end
  
  def body
    @body
  end
end

class MockHttp
  def request(r)
    raise "Bad response"
  end
end
