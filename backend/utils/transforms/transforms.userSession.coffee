{validators} = require '../util.validation'
config =  require '../../config/config'
emailTransforms = require './transforms.email'

root =
  PUT: () ->
    # Needs to be a function so that the email (validation) is invoked each time
    first_name: validators.string(minLength: 2)
    last_name: validators.string(minLength: 2)
    address_1: validators.string(regex: config.VALIDATION.address)
    address_2: validators.string(minLength: 2)
    city: validators.string(minLength: 2)
    us_state_id: required:true
    zip: required:true
    cell_phone:
      transform: [
        validators.string
          regex: config.VALIDATION.phone
          replace: [config.VALIDATION.phoneNonNumeric, '']
      ]
      required: true
    work_phone: validators.string
      regex: config.VALIDATION.phone
      replace: [config.VALIDATION.phoneNonNumeric, '']
    username:
      transform: [
        validators.string(minLength: 3)
      ]
      required: true
    website_url: validators.string(regex: config.VALIDATION.url)
    email: emailTransforms.email()
    account_use_type_id:
      transform: validators.integer()
      required:true

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
    properties_selected: validators.object()
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

module.exports = {
  root
  profiles
  companyImage
  companyRoot
  updatePassword
}
