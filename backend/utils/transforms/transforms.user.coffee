# _ = require 'lodash'
{validators} = require '../util.validation'
# emailTransformRegex = require('./transforms.email').regex
# {regexes} = require '../../../common/config/commonConfig'

image =
  account_image_id:
    transform: validators.integer()
    required: true

imageByUser =
  params: validators.object subValidateSeparate:
    id: validators.integer()
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true


permissions = do ->
  byIds =
    #inputs to re-route/map fields for m2m table updates
    user_id:
      input: 'id'
      transform: validators.integer()
      required: true
    id:
      input: 'permission_id'
      transform: validators.integer()
      required: true

  root =
    user_id:
      input: 'id'
      transform: validators.integer()
      required: true

  rootGET:
    params: validators.object subValidateSeparate: root
    query: validators.object isEmptyProtect: true
    body: validators.array()


  rootPOST:
    params: validators.object subValidateSeparate: root
    query: validators.object isEmptyProtect: true
    body: validators.array()

  byIdDELETE:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true

  byIdGET:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
  byIdPUT:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
  byIdPOST:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true

groups = do ->
  byIds =
    #inputs to re-route/map fields for m2m table updates
    user_id:
      input: 'id'
      transform: validators.integer()
      required: true
    id:
      input: 'group_id'
      transform: validators.integer()
      required: true

  root =
    user_id:
      input: 'id'
      transform: validators.integer()
      required: true

  rootGET:
    params: validators.object subValidateSeparate: root
    query: validators.object isEmptyProtect: true
    body: validators.array()


  rootPOST:
    params: validators.object subValidateSeparate: root
    query: validators.object isEmptyProtect: true
    body: validators.array()

  byIdDELETE:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true

  byIdGET:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
  byIdPUT:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
  byIdPOST:
    params: validators.object subValidateSeparate: byIds
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true


#TODO: allow validateAndRequest to only pass through original object keys
# _rootQueryAndBody =
#   first_name: validators.string(minLength:2)
#   last_name: validators.string(minLength:2)
#   email: emailTransformRegex
#
#   us_state_id: validators.integer()
#   parent_id: validators.integer()
#   company_id: validators.integer()
#   account_image_id: validators.integer()
#   account_use_type_id: validators.integer()
#
#   address_1: validators.string()
#   address_2: validators.string()
#   zip: validators.string()
#   city: validators.string()
#
#   is_staff: validators.boolean(truthy: true, falsy: false)
#   is_active: validators.boolean(truthy: true, falsy: false)
#   is_superuser: validators.boolean(truthy: true, falsy: false)
#   email_is_valid: validators.boolean(truthy: true, falsy: false)
#   is_test: validators.boolean(truthy: true, falsy: false)
#
#   work_phone: validators.string(regex: regexes.phone)
#   cell_phone: validators.string(regex: regexes.phone)
#   website_url: validators.string(regex: regexes.url)

root =
  POST:
    params: validators.object isEmptyProtect: true
    query: validators.object isEmptyProtect: true
    body: {} #validators.object subValidateSeparate: _rootQueryAndBody

  GET:
    params: validators.object isEmptyProtect: true
    query: {} #validators.object subValidateSeparate: _rootQueryAndBody
    body: {} #validators.object subValidateSeparate: _rootQueryAndBody

byId =
  POST:
    params: validators.object subValidateSeparate:
      id:
        transform: validators.integer()
        required: true
    query: {} #validators.object subValidateSeparate: _rootQueryAndBody
    body: {}
  PUT:
    params: validators.object subValidateSeparate:
      id:
        transform: validators.integer()
        required: true
    query: {} #validators.object subValidateSeparate: _rootQueryAndBody
    body: {}
  GET:
    params: validators.object subValidateSeparate:
      id:
        transform: validators.integer()
        required: true
    query: {} #validators.object subValidateSeparate: _rootQueryAndBody
    body: validators.object isEmptyProtect: true

  DELETE:
    params: validators.object subValidateSeparate:
      id:
        transform: validators.integer()
        required: true
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true


module.exports = {
  image
  imageByUser
  permissions
  groups
  root
  byId
}
