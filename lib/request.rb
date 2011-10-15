require 'rubygems'
require 'builder'
require 'rexml/document'

class Request
  def initialize(user, credentials)
    @user, @credentials = user, credentials
    puts credentials.to_yaml
  end
  
  def to_xml
    xml_request = Builder::XmlMarkup.new :indent => 2

    xml_request.instruct!
    xml_request.tag! 'NetConnectRequest', {
        :xmlns      => 'http://www.experian.com/NetConnect', 
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance' } do
      xml_request.EAI @credentials["eai"]
      xml_request.DBHost @credentials["db_host"]
      xml_request.ReferenceId('userlabc001')
      xml_request.Request(:xmlns => 'http://www.experian.com/WebDelivery', :version => '1.0') do 
        xml_request.Products do
          xml_request.PreciseID do
            xml_request.Subscriber do
              xml_request.Preamble @credentials["preamble"]
              xml_request.OpInitials('MP')
              xml_request.SubCode @credentials["subcode"]
            end
            xml_request.PrimaryApplicant do
              xml_request.Name do
                xml_request.Surname(@user[:last_name])
                xml_request.First(@user[:first_name])
              end
              xml_request.SSN @user[:ssn]
              xml_request.CurrentAddress do
                address = @user[:address1]
                address += " #{@user[:address2]}" if @user[:address2]
                xml_request.Street address
                xml_request.City @user[:city]
                xml_request.State @user[:state_province]
                xml_request.Zip @user[:postal_code]
              end
              xml_request.Phone do
                xml_request.Number @user[:phone]
                xml_request.Type 'R'
              end
              xml_request.DOB @user[:dob].strftime("%m%d%Y") if @user[:dob]
            end
            xml_request.AccountType do
              xml_request.Type '99'
            end
            xml_request.OutputType do
              xml_request.XML do
                xml_request.ARFVersion '07'
                xml_request.Verbose 'N'
              end
            end
            xml_request.Vendor do
              xml_request.VendorNumber @credentials["vendor_number"]
              xml_request.VendorVersion '1.0'
            end
            xml_request.Options do
              xml_request.ReferenceNumber 'FCRA Full Detail - Non Verbose XML'
              xml_request.PreciseIDType 'IG'
              xml_request.DetailRequest 'F'
              xml_request.StrategyNumber '01'
              xml_request.NFDAggregationFlag 'N'
              xml_request.DecisionScoreCutoffLow '001'
              xml_request.DecisionScoreCutoffHigh '123'
              xml_request.PreorPostEnrollment 'PREE'
              xml_request.InquiryChannel 'MAIL'
            end
          end
        end
      end
    end
    
    xml_request  
  end
end
