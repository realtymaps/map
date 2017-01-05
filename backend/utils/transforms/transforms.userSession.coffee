{validators} = require '../util.validation'
config =  require '../../config/config'
emailTransforms = require './transforms.email'

root =
  PUT: (userId) ->
    # Needs to be a function so that the email (validation) is invoked each time
    first_name:
      transforms: validators.string(minLength: 2)
      required: true
    last_name:
      transforms: validators.string(minLength: 2)
      required: true
    address_1: validators.string(regex: config.VALIDATION.address)
    address_2: validators.string(minLength: 2)
    city: validators.string(minLength: 2)
    us_state_id: {}
    zip: {}
    cell_phone: validators.string {
      regex: config.VALIDATION.phone
      replace: [config.VALIDATION.phoneNonNumeric, '']
    }
    work_phone: validators.string
      regex: config.VALIDATION.phone
      replace: [config.VALIDATION.phoneNonNumeric, '']
    username: validators.string(minLength: 3)
    website_url: validators.string(regex: config.VALIDATION.url)
    email:
      transforms: emailTransforms.valid(id:userId)
      required: true
    account_use_type_id: validators.integer()

profiles =
  PUT:
    project_id: validators.integer()
    account_image_id: validators.integer()
    filters: validators.object()
    favorites: validators.object()
    map_toggles: validators.object()
    map_position: validators.object()
    map_results: validators.object()
    auth_user_id: validators.integer()
    parent_auth_user_id: validators.integer()
    pins: validators.object()
    id:
      transforms: [validators.integer()]
      required: true

companyImage =
  GET:
    account_image_id:
      required: true

companyRoot =
  POST: () ->
    name: validators.string(minLength: 2)
    address_1: validators.string(regex: config.VALIDATION.address)
    address_2: validators.string(minLength: 2)
    city: validators.string(minLength: 2)
    us_state_id: required:true
    zip: required:true
    phone:
      transform: [
        validators.string
          regex: config.VALIDATION.phone
          replace: [config.VALIDATION.phoneNonNumeric, '']
      ]
      required: true
    fax: validators.string
      regex: config.VALIDATION.phone
      replace: [config.VALIDATION.phoneNonNumeric, '']
    website_url: validators.string(regex: config.VALIDATION.url)

updatePassword =
  password: validators.string(regex: config.VALIDATION.password)

requestResetPassword =
  email: validators.string(regex: config.VALIDATION.email)

doResetPassword =
  key: validators.string()
  email: validators.string(regex: config.VALIDATION.email)
  password: validators.string(regex: config.VALIDATION.password)

requestLoginToken =
  email: validators.string(regex: config.VALIDATION.email)

module.exports = {
  root
  profiles
  companyImage
  companyRoot
  updatePassword
  requestResetPassword
  doResetPassword
  requestLoginToken
}
