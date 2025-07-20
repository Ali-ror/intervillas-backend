details = ::MyBookingPal.client.pm_details.except("additionalContacts")

json.extract! details,
  "id",
  "isCompany",
  "policies",
  "payment"

json.set! :companyDetails, details["companyDetails"].except("transportCompanyAdditionalDetails")
