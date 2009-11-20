module Experian::Codes
  ADDRESS                       = 'Address'
  ADDRESS_TYPE                  = 'Address Type'
  PHONE                         = 'Phone'
  SSN                           = 'SSN'
  DOB                           = 'Date of birth'
  OFAC                          = 'OFAC'
  SCORE                         = 'Precise ID Score'
  
  EXPERIAN_CANNOT_CONNECT       = 10
  EXPERIAN_ALLOWED              = 0
  EXPERIAN_FRAUD                = 1

  MINIMUM_GOOD_SCORE            = 2
  
  # Version 1 - Users need to have address match + 3 other matches
  # Version 2 - Users need 2 matches
  # Version 3 - Only fraudulent users are rejected. Everyone else is either just good, or pending CS or CCO
  VERSION                       = 3
end
