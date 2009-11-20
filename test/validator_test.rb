require 'test/unit'
require '../extensions'
require 'validator'
require 'codes'

class ValidatorTest < Test::Unit::TestCase
  def test_should_not_be_good_match_score_if_precise_id_is_exclusion_score
    responses = {
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "H", 
      Codes::DOB     => "1", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "1000"}
    validator = Validator.new(responses)
    assert validator.match_score >= Codes::MINIMUM_GOOD_SCORE
    assert !validator.good_score?, "Precise id is bigger than 999 so this should be a bad score"
  end

  def test_should_be_good_match_score_if_precise_id_is_not_exclusion_score_and_match_score_is_more_than_minimum
    responses = {
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "H", 
      Codes::DOB     => "1", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "999"}
    validator = Validator.new(responses)
    assert validator.match_score >= Codes::MINIMUM_GOOD_SCORE
    assert validator.good_score?, "Precise id is just 999 so this should be a good score"
  end

  def test_should_be_bad_match_score_if_precise_id_is_not_exclusion_score_and_match_score_is_less_than_minimum
    responses = {
      Codes::ADDRESS => "X", 
      Codes::PHONE   => "X", 
      Codes::DOB     => "6", 
      Codes::SSN     => "X", 
      Codes::SCORE   => "300"}
    validator = Validator.new(responses)
    assert validator.match_score < Codes::MINIMUM_GOOD_SCORE
    assert !validator.good_score?, "Precise id is less than 999 but bad match score, so this should be bad"
  end
  
  def test_should_return_the_key_as_score_if_key_not_found
    responses = {
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "H", 
      Codes::DOB     => "1", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "1"}
    validator = Validator.new(responses)
    assert_equal "foo", validator.score_for("foo"), "Since there is not score for 'foo' we should have returned 'foo' as the score"
  end
  
  def test_should_validate_when_match_score_is_2_or_more
    responses = {
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "H", 
      Codes::DOB     => "1", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 6, @validator.match_score
    assert @validator.match?

    responses = {
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "H", 
      Codes::DOB     => "X", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 5, @validator.match_score
    assert @validator.match?

    responses = {
      Codes::ADDRESS => "X", 
      Codes::PHONE   => "H", 
      Codes::DOB     => "1", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 4, @validator.match_score
    assert @validator.match?

    responses = {
      Codes::ADDRESS => "X", 
      Codes::PHONE   => "A", 
      Codes::DOB     => "1", 
      Codes::SSN     => "A", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 3, @validator.match_score
    assert @validator.match?

    responses = {
      Codes::ADDRESS => "X", 
      Codes::PHONE   => "X", 
      Codes::DOB     => "1", 
      Codes::SSN     => "FY", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 2, @validator.match_score
    assert @validator.match?

    responses = {
      Codes::ADDRESS => "X", 
      Codes::PHONE   => "HB", 
      Codes::DOB     => "2", 
      Codes::SSN     => "X", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 2, @validator.match_score
    assert @validator.match?
  end

  def test_should_not_pass_if_there_is_match_score_is_lower_than_2
    responses = {
      Codes::ADDRESS => "X", 
      Codes::PHONE   => "X", 
      Codes::DOB     => "1", 
      Codes::SSN     => "X", 
      Codes::SCORE   => "1"}
    @validator = Validator.new(responses)
    assert 1, @validator.match_score
    assert !@validator.match?
  end

  def test_should_match_address
    %w{S SM Y YB YM}.each do |code|
      responses = {
        Codes::ADDRESS => code}
      @validator = Validator.new(responses)
      assert_equal 1, @validator.address_score, "bad code: #{code}"
    end
  end
  
  def test_should_be_valid_if_score_is_525_or_more
    responses = {
      Codes::SCORE   => "525", 
      Codes::SSN     => "FY", 
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "H"}
    @validator = Validator.new(responses)
    assert @validator.match?
    assert_equal 5, @validator.match_score
  end

  def test_should_still_be_valid_if_score_is_less_than_525
    responses = {
      Codes::SCORE   => "0", 
      Codes::SSN     => "FY", 
      Codes::ADDRESS => "S", 
      Codes::PHONE   => "F"}
    @validator = Validator.new(responses)
    assert @validator.match?
    assert_equal 4, @validator.match_score
  end
  
  def test_should_match_ssn
    %w{FY SA YA YB}.each do |code|
      responses = {Codes::SSN => code}
      @validator = Validator.new(responses)
      assert_equal 2, @validator.ssn_score, "bad code: #{code}"
    end

    %w{A FF S Y}.each do |code|
      responses = {Codes::SSN => code}
      @validator = Validator.new(responses)
      assert_equal 1, @validator.ssn_score, "bad code: #{code}"
    end
  end
  
  def test_should_not_match_ssn
    %w{X B Z}.each do |code|
      responses = {Codes::SSN => code}
      @validator = Validator.new(responses)
      assert_equal 0, @validator.ssn_score, "bad code: #{code}"
    end
  end
  
  def test_should_match_phone
    %w{A AB AM C F FB FM S SM}.each do |code|
      responses = {Codes::PHONE => code}
      @validator = Validator.new(responses)
      assert_equal 1, @validator.phone_score
    end

    %w{H HB HM Y YB YM}.each do |code|
      responses = {Codes::PHONE => code}
      @validator = Validator.new(responses)
      assert_equal 2, @validator.phone_score
    end
  end
  
  def test_should_not_match_phone
    %w{I X}.each do |code|
      responses = {Codes::PHONE => code}
      @validator = Validator.new(responses)
      assert_equal 0, @validator.phone_score
    end
  end

  def test_should_match_dob
    responses = {Codes::DOB => "1"}
    @validator = Validator.new(responses)
    assert_equal 1, @validator.dob_score
  end

  def test_should_not_match_dob
    responses = {Codes::DOB => "2"}
    @validator = Validator.new(responses)
    assert_equal 0, @validator.dob_score

    responses = {Codes::DOB => "0"}
    @validator = Validator.new(responses)
    assert_equal 0, @validator.dob_score
  end

  def test_should_pass_ofac_if_code_is_positive
    responses = {Codes::OFAC => "2"}
    @validator = Validator.new(responses)
    assert @validator.on_ofac?

    responses = {Codes::OFAC => "11"}
    @validator = Validator.new(responses)
    assert @validator.on_ofac?
  end

  def test_should_not_pass_ofac_if_code_is_not_positive
    Codes::VALID_OFAC_CODES.each do |good_ofac_code|
      responses = {Codes::OFAC => good_ofac_code}
      @validator = Validator.new(responses)
      assert !@validator.on_ofac?, "OFAC #{good_ofac_code} should be valid"
    end

    responses = {Codes::OFAC => "-1"}
    @validator = Validator.new(responses)
    assert @validator.on_ofac?
  end

  def test_should_be_valid_with_some_of_the_v1_fraud_codes
    ['V', 'VB', 'VM', 'VS', 'VX'].each do |code|
      responses = {
        Codes::ADDRESS_TYPE => code, 
        Codes::SSN          => "N"
      }
      @validator = Validator.new(responses)
      assert !@validator.fraud_code_match?
    end

    ['I', 'N', 'F'].each do |code|
      responses = {Codes::SSN => code}
      @validator = Validator.new(responses)
      assert !@validator.fraud_code_match?
    end
  end

  def test_should_be_invalid_if_fraudulent
    ['D', 'DS', 'DN', 'DY'].each do |code|
      responses = {Codes::SSN => code}
      @validator = Validator.new(responses)
      assert @validator.fraud_code_match?
    end
  end
  
  def test_should_get_zeroes_for_missing_codes
    validator = Validator.new({})
    assert validator.fraud_code_match?
    assert_equal 0, validator.ssn_score
    assert_equal 0, validator.address_score
    assert_equal 0, validator.dob_score
    assert_equal 0, validator.phone_score
  end
end
