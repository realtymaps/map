{validators, requireAllTransforms} = require '../util.validation'
{VALIDATION}= require '../../config/config'
emailTransforms = require('./transforms.email')

module.exports =
  createUser:
    params: validators.object isEmptyProtect: true
    query: validators.object isEmptyProtect: true
    body: validators.object subValidateSeparate: requireAllTransforms
      ###
        password: *************
        email: "someAhole@gmail.com"
        fips_code: "12021"
        first_name: "nem"
        last_name: "mc"
        us_state_code: "FL"
        zip: "12344"
      ###
      password: validators.string(regex: VALIDATION.password)
      email: emailTransforms
      fips_code: validators.string(minLength: 5)
      first_name: validators.string(minLength: 2)
      last_name: validators.string(minLength: 2)

      plan: validators.object subValidateSeparate: requireAllTransforms
        name: validators.string(minLength: 3)
      ###
        card: Object
          id: "tok_17QgRs2eZvKYlo2CEpUvnwk3" ALIAS token
          brand: "Visa"
          country: "US"
          cvc_check: "unchecked"
          exp_month: 12
          exp_year: 2020
          funding: "credit"
          last4: "4242"
      ###
      token: validators.object subValidateSeparate: requireAllTransforms
        id: validators.string(minLength: 28)
        card: validators.object subValidateSeparate: requireAllTransforms
          id: validators.string(minLength: 28)
        # brand: validators.string(minLength: 2)
        # country: validators.string(minLength: 2)
        # cvc_check: validators.string(minLength: 2)
        # exp_month: [validators.string(minLength: 2, allowNumber: true), validators.integer()]
        # exp_year: [validators.string(minLength: 4, allowNumber: true), validators.integer()]
        # funding: validators.string(minLength: 2) #should we force credit?
        # last4: validators.string(minLength: 4)
