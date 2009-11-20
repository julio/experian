class Experian::Validator
  include Experian::Codes

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
    EXPERIAN[:minimum_score]
  end
  
  def score_for(key)
    return ssn_score     if key == SSN
    return address_score if key == ADDRESS
    return phone_score   if key == PHONE
    return dob_score     if key == DOB
    key
  end
  
  def exclusion_score?
    precise_id_score > 999
  end
  
  def precise_id_score
    @responses[SCORE].to_i
  end
  
  def on_ofac?
    !EXPERIAN[:valid_ofac_codes].include?(@responses[OFAC].to_i)
  end
  
  def fraud_code_match?
    return true if @responses[SSN].blank?
    ['D', 'DS', 'DN', 'DY', 'NI'].include?(@responses[SSN])
  end

  def ssn_score
    return 0 if @responses[SSN].blank?
    
    if %w{A FF S Y}.include?(@responses[SSN])
      1
    elsif %w{FY SA YA YB}.include?(@responses[SSN])
      2
    else
      0
    end
  end
  
  def phone_score
    return 0 if @responses[PHONE].blank?
    
    if %{A AB AM C F FB FM S SB SM}.include?(@responses[PHONE])
      1
    elsif %{H HB HM Y YB YM}.include?(@responses[PHONE])
      2
    else
      0
    end
  end

  def address_score
    return 0 if @responses[ADDRESS].blank?
    
    %{S SM Y YB YM}.include?(@responses[ADDRESS]) ? 1 : 0
  end

  def dob_score
    return 0 if @responses[DOB].blank?
    
    @responses[DOB] == '1' ? 1 : 0
  end
end

