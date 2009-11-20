# The response we get from Experian will be parsed and a score
# will be calculated. Given that Experian doesn't give a yes/no 
# answer, it's better to calculate this score based on your
# business rules. In this particular implementation, the (hardcoded)
# rules say that a a score of 2 or less isn't so good.
class Validator
  def initialize(responses)
    @responses = responses
  end
  
  def match?
    fraud_code_match? ? false : good_score?
  end
  
  def match_score
    ssn_score + phone_score + dob_score + address_score
  end
  
  def good_score?
    match_score >= minimum_good_match_score && !exclusion_score?
  end
  
  def minimum_good_match_score
    Codes::MINIMUM_GOOD_SCORE
  end
  
  def score_for(key)
    return ssn_score     if key == Codes::SSN
    return address_score if key == Codes::ADDRESS
    return phone_score   if key == Codes::PHONE
    return dob_score     if key == Codes::DOB
    key
  end
  
  def exclusion_score?
    precise_id_score > 999
  end
  
  def precise_id_score
    @responses[Codes::SCORE].to_i
  end
  
  def on_ofac?
    !Codes::VALID_OFAC_CODES.include?(@responses[Codes::OFAC].to_i)
  end
  
  def fraud_code_match?
    return true if @responses[Codes::SSN].blank?
    ['D', 'DS', 'DN', 'DY', 'NI'].include?(@responses[Codes::SSN])
  end

  def ssn_score
    return 0 if @responses[Codes::SSN].blank?
    
    if %w{A FF S Y}.include?(@responses[Codes::SSN])
      1
    elsif %w{FY SA YA YB}.include?(@responses[Codes::SSN])
      2
    else
      0
    end
  end
  
  def phone_score
    return 0 if @responses[Codes::PHONE].blank?
    
    if %{A AB AM C F FB FM S SB SM}.include?(@responses[Codes::PHONE])
      1
    elsif %{H HB HM Y YB YM}.include?(@responses[Codes::PHONE])
      2
    else
      0
    end
  end

  def address_score
    return 0 if @responses[Codes::ADDRESS].blank?
    
    %{S SM Y YB YM}.include?(@responses[Codes::ADDRESS]) ? 1 : 0
  end

  def dob_score
    return 0 if @responses[Codes::DOB].blank?
    
    @responses[Codes::DOB] == '1' ? 1 : 0
  end
end

