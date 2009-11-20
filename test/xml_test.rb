require 'test/unit'
require 'codes'
require 'xml'

class XmlTest < Test::Unit::TestCase
  def test_should_convert_full_xml_to_responses
    xml_converter = Xml.new(xml_response)
    responses = xml_converter.to_responses

    assert_equal 7, responses.size
    assert_equal "***ADDRESS***",      responses[Codes::ADDRESS]
    assert_equal "***ADDRESS_TYPE***", responses[Codes::ADDRESS_TYPE]
    assert_equal "***PHONE***",        responses[Codes::PHONE]
    assert_equal "***SSN***",          responses[Codes::SSN]
    assert_equal "***DOB***",          responses[Codes::DOB]
    assert_equal "***OFAC***",         responses[Codes::OFAC]
  end

  def test_should_fail_gracefully_with_empty_xml_response
    xml = Xml.new("")
    doc = REXML::Document.new
    assert_equal '', xml.get_response_code(doc, 'UNDEFINED')
  end

  private

  def xml_response
    response = <<-EXPERIAN_RESPONSE 
    <?xml version="1.0" standalone="no"?>
    <NetConnectResponse xmlns="http://www.experian.com/NetConnectResponse">
      <CompletionCode>0000</CompletionCode>
      <ReferenceId>userlabc001</ReferenceId>
      <Products xmlns="http://www.experian.com/ARFResponse">
        <PreciseID>
          <Header>
            <ReportDate>07202007</ReportDate>
            <ReportTime>161356</ReportTime>
            <Preamble>TBD1</Preamble>
            <ARFVersion>07</ARFVersion>
            <ReferenceNumber>FCRA FULL DETAIL - NON VERBOSE</ReferenceNumber>
          </Header>
          <Summary>
            <ReviewReferenceID>000708140AB</ReviewReferenceID>
            <PreciseIDType>G</PreciseIDType>
            <PreciseIDScore>000509</PreciseIDScore>
            <PreciseIDScorecard>GLB Innovate Model</PreciseIDScorecard>
            <ValidationScore>000265</ValidationScore>
            <ValidationScorecard>GLB Validation Score</ValidationScorecard>
            <VerificationScore>000579</VerificationScore>
            <VerificationScorecard>GLB Verification Sco</VerificationScorecard>
            <ComplianceDescription>No Compliance Code</ComplianceDescription>
            <FPDScore>000001</FPDScore>
            <UtilityFunction>00000404</UtilityFunction>
            <OutofWalletScore>000000</OutofWalletScore>
            <InitialResults>
              <AuthenticationIndex>0000</AuthenticationIndex>
              <MostLikelyFraudType>RIN</MostLikelyFraudType>
              <Reasons>
                <Reason1 code="    "/>
                <Reason2 code="    "/>
                <Reason3 code="    "/>
                <Reason4 code="    "/>
              </Reasons>
              <InitialDecision>ACC</InitialDecision>
              <FinalDecision>ACC</FinalDecision>
              <ActionPath>000</ActionPath>
            </InitialResults>
            <Call2Results>
              <AuthenticationIndex>0000</AuthenticationIndex>
              <Reasons>
                <Reason1 code="    "/>
                <Reason2 code="    "/>
                <Reason3 code="    "/>
                <Reason4 code="    "/>
              </Reasons>
            </Call2Results>
            <NFDResults>
              <NFDIndex>000000</NFDIndex>
              <Reasons>
                <Reason1 code="    "/>
                <Reason2 code="    "/>
                <Reason3 code="    "/>
                <Reason4 code="    "/>
              </Reasons>
            </NFDResults>
          </Summary>
          <GLBDetail>
            <CheckpointSummary>
              <PrimaryResultCode>0</PrimaryResultCode>
              <BestPickAcceptDeny code=" "/>
              <AddrCode>U</AddrCode>
              <PhnCode>X</PhnCode>
              <AddrTypeCode>N</AddrTypeCode>
              <COACode>N</COACode>
              <SSNCode>V</SSNCode>
              <DLResultCode>NA</DLResultCode>
              <DateOfBirthMatch>6</DateOfBirthMatch>
              <HighRiskAddrCode>N</HighRiskAddrCode>
              <HighRiskPhoneCode>N</HighRiskPhoneCode>
              <OFACValidationResult>1</OFACValidationResult>
              <AddrResMatches>0000</AddrResMatches>
              <AddrBusMatches>0000</AddrBusMatches>
              <PhnResMatches>0000</PhnResMatches>
              <PhnBusMatches>0000</PhnBusMatches>
            </CheckpointSummary>
            <FraudShield>
              <FS01>N</FS01>
              <FS02>N</FS02>
              <FS03>N</FS03>
              <FS04>N</FS04>
              <FS05>N</FS05>
              <FS06>N</FS06>
              <FS10>N</FS10>
              <FS11>N</FS11>
              <FS13>N</FS13>
              <FS14>N</FS14>
              <FS15>N</FS15>
              <FS16>N</FS16>
              <FS17>N</FS17>
              <FS18>N</FS18>
              <FS21>Y</FS21>
              <FS25>N</FS25>
              <FS26>N</FS26>
              <FS27>N</FS27>
            </FraudShield>
            <SharedApplication>
              <GLBRule>28512452185212031001185424543001</GLBRule>
            </SharedApplication>
          </GLBDetail>
          <CheckPoint>
            <GeneralResults>
              <ProfileID>MMHX610</ProfileID>
              <AccountInformation>FCRA FULL DETAIL - NON VERBOSE</AccountInformation>
              <Version>15</Version>
              <PrimaryResult code="00"/>
              <BestPickAcceptDeny code=" "/>
              <CheckpointTemplate>STDADD</CheckpointTemplate>
              <NameFlipIndicator code=" "/>
              <AddressVerificationResult code="***ADDRESS***"/>
              <AddressUnitMismatchResult code="  "/>
              <PhoneVerificationResult code="***PHONE***"/>
              <PhoneUnitMismatchResult code="  "/>
              <AddressTypeResult code="***ADDRESS_TYPE***"/>
              <AddressVerificationResidentialMatches>0000</AddressVerificationResidentialMatches>
              <AddressVerificationBusinessMatches>0000</AddressVerificationBusinessMatches>
              <PhoneVerificationResidentialMatches>0000</PhoneVerificationResidentialMatches>
              <PhoneVerificationBusinessMatches>0000</PhoneVerificationBusinessMatches>
              <AddressHighRiskResult code="N "/>
              <PhoneHighRiskResult code="N "/>
              <COAResult code="N "/>
              <SSNResult code="***SSN***"/>
              <AcceptDeclineFlag code=" "/>
              <EDAResult code="NA"/>
              <CheckpointScore>310</CheckpointScore>
              <Result code="R"/>
              <AuditNumber>CP-ZC4-C5RKF213</AuditNumber>
              <ShortAuditNumber>8C5RKF2</ShortAuditNumber>
              <DriverLicenseResult code="Y"/>
              <DateOfBirthMatch code="***DOB***"/>
              <OFACResult code="***OFAC***"/>
              <StandardizedAddressRecordsReturned>01</StandardizedAddressRecordsReturned>
              <ResidentialAddressDetailRecordsReturned>00</ResidentialAddressDetailRecordsReturned>
              <BusinessAddressDetailRecordsReturned>00</BusinessAddressDetailRecordsReturned>
              <AddressHighRiskDetailRecordsReturned>00</AddressHighRiskDetailRecordsReturned>
              <AddressHighRiskDescriptionRecordsReturned>01</AddressHighRiskDescriptionRecordsReturned>
              <ResidentialPhoneDetailRecordsReturned>00</ResidentialPhoneDetailRecordsReturned>
              <BusinessPhoneDetailRecordsReturned>00</BusinessPhoneDetailRecordsReturned>
              <PhoneHighRiskDetailRecordsReturned>00</PhoneHighRiskDetailRecordsReturned>
              <PhoneHighRiskDescriptionRecordsReturned>00</PhoneHighRiskDescriptionRecordsReturned>
              <SSNAddressDetailRecordsReturned>00</SSNAddressDetailRecordsReturned>
              <ValidationSegmentsReturned>00</ValidationSegmentsReturned>
              <DriverLicenseSegmentsReturned>00</DriverLicenseSegmentsReturned>
              <OFACRecordSegmentsReturned>00</OFACRecordSegmentsReturned>
              <AuditRequestInformationRecordsReturned>00</AuditRequestInformationRecordsReturned>
              <COARecordsReturned>00</COARecordsReturned>
              <COADescriptionRecordsReturned>00</COADescriptionRecordsReturned>
              <PreviousAddressesReturned>00</PreviousAddressesReturned>
              <SSNFinderAddressesReturned>00</SSNFinderAddressesReturned>
            </GeneralResults>
            <StandardizedAddressDetail>
              <Surname>RATLIFF</Surname>
              <FirstName>BURT</FirstName>
              <Initial>E</Initial>
              <Address>2075 MASON DR</Address>
              <City>HAYNESVILLE</City>
              <State>LA</State>
              <ZipCode>71038</ZipCode>
              <ZipPlus4>6011</ZipPlus4>
            </StandardizedAddressDetail>
            <AddressHighRiskDescription>
              <HighRiskDescription>No high risk business at address/phone</HighRiskDescription>
            </AddressHighRiskDescription>
          </CheckPoint>
        </PreciseID>
      </Products>
    </NetConnectResponse>

     EXPERIAN_RESPONSE
  end
end
