require "net/https"
require "openssl"
require "uri"

class Experian
  include Experian::Codes
  include Exceptions
  
  def initialize(user)
    @user = user
  end
  
  def get_post_url
    Net::HTTP.start(CONFIG["experian"]["host"]) do |http|
      response = http.get(CONFIG["experian"]["path"])
      post_url = URI.parse(response.body.strip)
      exc = InvalidExperianUrl.new("Expected experian API URL with host '*.experian.com'. Instead we got '#{post_url.host}'")
      raise "Invalid Experian Response: <#{post_url}>, Status: #{response.code}" unless post_url && post_url.host
      raise exc unless post_url.host.ends_with?(".experian.com")
      post_url
    end
  end
  
  def check_user
    return EXPERIAN_ALLOWED if EXPERIAN[:disabled]

    xml_response = get_xml_response

    return EXPERIAN_CANNOT_CONNECT if xml_response.blank?
    
    xml_converter = Experian::Xml.new(xml_response.body)
    responses = xml_converter.to_responses
    validator = Experian::Validator.new(responses)
    update_user_status(@user, validator)
    process_experian_result(@user, validator, responses, xml_response.body)
  end

  def update_user_status(user, validator)
    if validator.on_ofac?
      user.account_status = validator.good_score? ? StatusCodes::USER_PENDING_OFAC : StatusCodes::USER_PENDING_OFAC_AND_CS
    else
      user.account_status = validator.good_score? ? StatusCodes::USER_ACTIVE : StatusCodes::USER_PENDING_CS
    end  
  end
  
  def get_xml_response
    request = Experian::Request.new(@user)
    xml_request = request.to_xml
    post_url = nil
    begin
      post_url = get_post_url
    rescue Exception => e
      return nil
    end
    xml_response = nil
    begin
      xml_response = send_request(xml_request, post_url)
    rescue Exception => e
      return nil
    end

    unless valid_xml_response?(xml_response)
      return nil
    end
    
    return xml_response
  end
  
  def valid_xml_response?(xml)
    !xml.blank? && !xml.body.blank?
  end
  
  def send_request(xml, post_url)
    http = Net::HTTP.new(post_url.host, post_url.port)
    http.use_ssl = true

    if EXPERIAN[:verify_certificate]
      http.ca_file = "#{PRIVATE_SHARED_ROOT}/pems/verisign.pem"
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    else
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.start do |http|
      request = Net::HTTP::Post.new("#{post_url.path}?#{post_url.query}")
      request.basic_auth CONFIG["experian"]["username"], CONFIG["experian"]["password"]
      request.set_form_data({'NETCONNECT_TRANSACTION' => xml.target!})
      return get_response(http, request)
    end
  end

  def get_response(http, request)
    begin
      http.request(request)
    rescue Exception => e
      raise e
    end
  end
  
  def process_experian_result(user, validator, responses, xml_response)
    create_experian_result(user, validator, responses, xml_response)

    return EXPERIAN_ALLOWED if accepting_all_responses?

    match_code = match_code(validator)

    match_code
  end
  
  def match_code(validator)
    validator.fraud_code_match? ? EXPERIAN_FRAUD : EXPERIAN_ALLOWED
  end
  
  def accepting_all_responses?
    EXPERIAN[:disabled]
  end

  def create_experian_result(user, validator, responses, original_xml_response)
    experian_result = ExperianResult.new
    experian_result.first_name    = user.first_name
    experian_result.last_name     = user.last_name
    experian_result.score         = validator.precise_id_score
    experian_result.ofac          = responses[OFAC]
    experian_result.ofac_score    = !validator.on_ofac?
    experian_result.ssn           = responses[SSN]
    experian_result.ssn_score     = validator.ssn_score
    experian_result.phone         = responses[PHONE]
    experian_result.phone_score   = validator.phone_score
    experian_result.address       = responses[ADDRESS]
    experian_result.address_score = validator.address_score
    experian_result.address_type  = responses[ADDRESS_TYPE]
    experian_result.dob           = responses[DOB]
    experian_result.dob_score     = validator.dob_score
    experian_result.fraud         = validator.fraud_code_match?
    experian_result.match_count   = validator.match_score
    experian_result.passed        = validator.match?
    experian_result.version       = VERSION
    experian_result.ip            = user.ip
    experian_result.xml_response  = original_xml_response
    experian_result.save
    user.experian_result_id = experian_result.id
  end  
end
