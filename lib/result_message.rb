module Experian::ResultMessage
  KEYS = {
    :ofac         => Experian::Codes::OFAC,
    :phone        => Experian::Codes::PHONE,
    :address      => Experian::Codes::ADDRESS,
    :address_type => Experian::Codes::ADDRESS_TYPE,
    :dob          => Experian::Codes::DOB,
    :ssn          => Experian::Codes::SSN
  }
  def self.get(experian_key, message_key)
    "#{message_key}: " + Messages["experian_#{experian_key}/m_#{message_key}"]
  end
end
