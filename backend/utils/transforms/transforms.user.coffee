{validators} = require '../util.validation'


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


module.exports = {
  image
  imageByUser
  permissions
  groups
}
