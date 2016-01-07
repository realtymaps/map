{validators, falsyDefaultTransformsToNoop} = require '../util.validation'
{VALIDATION}= require '../../config/config'
emailTransforms = require('./transforms.email')

module.exports =
  verify: falsyDefaultTransformsToNoop
    params: validators.object isEmptyProtect: true
    query:  validators.object isEmptyProtect: true
    body:
      password: validators.string(regex: VALIDATION.password)
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
      card:
        state: validators.object
          subValidateSeparate:
            id:
              transform: [validators.string(minLength: 28)]
              required: true
            brand:
              transform: [validators.string(minLength: 2)]
              required: true
            country:
              transform: [validators.string(minLength: 2)]
              required: true
            cvc_check:
              transform: [validators.string(minLength: 2)]
            exp_month:
              transform: [validators.string(minLength: 2, allowNumber: true), validators.integer()]
              required: true
            exp_year:
              transform: [validators.string(minLength: 4, allowNumber: true), validators.integer()]
              required: true
            funding:
              transform: [validators.string(minLength: 2)]#should we force credit?
              required: true
            last4:
              transform: [validators.string(minLength: 4)]
              required: true
      ###
        email: "nemtcan@gmail.com"
        fips_code: "12021"
        first_name: "nem"
        last_name: "mc"
        us_state_code: "FL"
        zip: "12344"
      ###
      email: emailTransforms
      fips_code:
        transform: [validators.string(minLength: 5)]
        required: true
      first_name:
        transform: [validators.string(minLength: 2)]
        required: true
      last_name:
        transform: [validators.string(minLength: 2)]
        required: true
